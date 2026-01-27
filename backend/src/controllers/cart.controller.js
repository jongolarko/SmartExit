const crypto = require("crypto");
const pool = require("../config/db");
const { emitCartUpdate } = require("../config/socket");
const { success, error } = require("../utils/response");

// Helper to get cart with items
async function getCartData(userId) {
  const result = await pool.query(
    `SELECT
       ci.id as item_id,
       ci.quantity,
       ci.price as unit_price,
       (ci.quantity * ci.price) as total_price,
       p.id as product_id,
       p.barcode,
       p.name,
       p.description,
       p.image_url
     FROM carts c
     JOIN cart_items ci ON c.id = ci.cart_id
     JOIN products p ON ci.product_id = p.id
     WHERE c.user_id = $1 AND c.status = 'active'
     ORDER BY ci.created_at DESC`,
    [userId]
  );

  const items = result.rows;
  const total = items.reduce((sum, item) => sum + parseFloat(item.total_price), 0);
  const itemCount = items.reduce((sum, item) => sum + item.quantity, 0);

  return {
    items,
    total: parseFloat(total.toFixed(2)),
    item_count: itemCount,
  };
}

// GET /cart - Get user's cart
async function getCart(req, res, next) {
  try {
    const userId = req.user.user_id;
    const cartData = await getCartData(userId);
    return success(res, cartData);
  } catch (err) {
    next(err);
  }
}

// POST /cart/add - Add item to cart
async function addToCart(req, res, next) {
  try {
    const { barcode, quantity = 1 } = req.body;
    const userId = req.user.user_id;

    // Find product
    const productRes = await pool.query(
      "SELECT * FROM products WHERE barcode = $1",
      [barcode]
    );

    if (productRes.rows.length === 0) {
      return error(res, "Product not found", 404);
    }

    const product = productRes.rows[0];

    // Check stock availability
    if (product.stock !== null && product.stock < quantity) {
      return error(res, "Insufficient stock", 400);
    }

    // Get or create active cart
    let cartRes = await pool.query(
      "SELECT * FROM carts WHERE user_id = $1 AND status = 'active'",
      [userId]
    );

    let cartId;
    if (cartRes.rows.length === 0) {
      cartId = crypto.randomUUID();
      await pool.query(
        "INSERT INTO carts (id, user_id, status, created_at) VALUES ($1, $2, 'active', NOW())",
        [cartId, userId]
      );
    } else {
      cartId = cartRes.rows[0].id;
    }

    // Add or update cart item
    await pool.query(
      `INSERT INTO cart_items (id, cart_id, product_id, quantity, price, created_at)
       VALUES ($1, $2, $3, $4, $5, NOW())
       ON CONFLICT (cart_id, product_id)
       DO UPDATE SET quantity = cart_items.quantity + EXCLUDED.quantity`,
      [crypto.randomUUID(), cartId, product.id, quantity, product.price]
    );

    // Get updated cart data
    const cartData = await getCartData(userId);

    // Emit realtime update
    emitCartUpdate(userId, cartData);

    return success(res, {
      message: "Added to cart",
      ...cartData,
    });
  } catch (err) {
    next(err);
  }
}

// PUT /cart/item/:itemId - Update cart item quantity
async function updateCartItem(req, res, next) {
  try {
    const { itemId } = req.params;
    const { quantity } = req.body;
    const userId = req.user.user_id;

    // Verify item belongs to user's cart
    const itemRes = await pool.query(
      `SELECT ci.*, c.user_id, p.stock
       FROM cart_items ci
       JOIN carts c ON ci.cart_id = c.id
       JOIN products p ON ci.product_id = p.id
       WHERE ci.id = $1 AND c.status = 'active'`,
      [itemId]
    );

    if (itemRes.rows.length === 0) {
      return error(res, "Cart item not found", 404);
    }

    const item = itemRes.rows[0];

    if (item.user_id !== userId) {
      return error(res, "Access denied", 403);
    }

    // Check stock
    if (item.stock !== null && item.stock < quantity) {
      return error(res, "Insufficient stock", 400);
    }

    // Update quantity
    await pool.query(
      "UPDATE cart_items SET quantity = $1 WHERE id = $2",
      [quantity, itemId]
    );

    // Get updated cart data
    const cartData = await getCartData(userId);

    // Emit realtime update
    emitCartUpdate(userId, cartData);

    return success(res, {
      message: "Cart updated",
      ...cartData,
    });
  } catch (err) {
    next(err);
  }
}

// DELETE /cart/item/:itemId - Remove item from cart
async function removeCartItem(req, res, next) {
  try {
    const { itemId } = req.params;
    const userId = req.user.user_id;

    // Verify item belongs to user's cart
    const itemRes = await pool.query(
      `SELECT ci.*, c.user_id
       FROM cart_items ci
       JOIN carts c ON ci.cart_id = c.id
       WHERE ci.id = $1 AND c.status = 'active'`,
      [itemId]
    );

    if (itemRes.rows.length === 0) {
      return error(res, "Cart item not found", 404);
    }

    if (itemRes.rows[0].user_id !== userId) {
      return error(res, "Access denied", 403);
    }

    // Delete item
    await pool.query("DELETE FROM cart_items WHERE id = $1", [itemId]);

    // Get updated cart data
    const cartData = await getCartData(userId);

    // Emit realtime update
    emitCartUpdate(userId, cartData);

    return success(res, {
      message: "Item removed from cart",
      ...cartData,
    });
  } catch (err) {
    next(err);
  }
}

// DELETE /cart - Clear entire cart
async function clearCart(req, res, next) {
  try {
    const userId = req.user.user_id;

    // Get active cart
    const cartRes = await pool.query(
      "SELECT id FROM carts WHERE user_id = $1 AND status = 'active'",
      [userId]
    );

    if (cartRes.rows.length > 0) {
      const cartId = cartRes.rows[0].id;

      // Delete all items
      await pool.query("DELETE FROM cart_items WHERE cart_id = $1", [cartId]);

      // Delete cart
      await pool.query("DELETE FROM carts WHERE id = $1", [cartId]);
    }

    const cartData = { items: [], total: 0, item_count: 0 };

    // Emit realtime update
    emitCartUpdate(userId, cartData);

    return success(res, {
      message: "Cart cleared",
      ...cartData,
    });
  } catch (err) {
    next(err);
  }
}

module.exports = {
  getCart,
  addToCart,
  updateCartItem,
  removeCartItem,
  clearCart,
  getCartData,
};
