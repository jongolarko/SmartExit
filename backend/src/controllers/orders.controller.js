const pool = require("../config/db");
const { success, error, paginated } = require("../utils/response");

// GET /orders - Get current user's orders
async function getMyOrders(req, res, next) {
  try {
    const userId = req.user.user_id;
    const { page = 1, limit = 20 } = req.query;
    const offset = (page - 1) * limit;

    const result = await pool.query(
      `SELECT o.id, o.total_amount, o.status, o.created_at, o.paid_at,
              (SELECT COUNT(*) FROM order_items WHERE order_id = o.id) as item_count
       FROM orders o
       WHERE o.user_id = $1 AND o.status = 'paid'
       ORDER BY o.created_at DESC
       LIMIT $2 OFFSET $3`,
      [userId, limit, offset]
    );

    const countRes = await pool.query(
      "SELECT COUNT(*) FROM orders WHERE user_id = $1 AND status = 'paid'",
      [userId]
    );

    return paginated(
      res,
      result.rows,
      parseInt(page),
      parseInt(limit),
      parseInt(countRes.rows[0].count)
    );
  } catch (err) {
    next(err);
  }
}

// GET /orders/:id - Get order details
async function getOrderDetails(req, res, next) {
  try {
    const userId = req.user.user_id;
    const { id } = req.params;

    // Get order (must belong to user)
    const orderRes = await pool.query(
      `SELECT o.id, o.total_amount, o.status, o.created_at, o.paid_at,
              o.razorpay_order_id, o.razorpay_payment_id
       FROM orders o
       WHERE o.id = $1 AND o.user_id = $2`,
      [id, userId]
    );

    if (orderRes.rows.length === 0) {
      return error(res, "Order not found", 404);
    }

    // Get order items
    const itemsRes = await pool.query(
      `SELECT oi.id, oi.quantity, oi.price,
              p.name, p.barcode, p.description, p.image_url
       FROM order_items oi
       JOIN products p ON oi.product_id = p.id
       WHERE oi.order_id = $1`,
      [id]
    );

    // Get exit status
    const exitRes = await pool.query(
      `SELECT exit_token, verified, allowed, expires_at, verified_at, created_at
       FROM gate_access
       WHERE order_id = $1
       ORDER BY created_at DESC LIMIT 1`,
      [id]
    );

    return success(res, {
      order: orderRes.rows[0],
      items: itemsRes.rows,
      exit: exitRes.rows[0] || null,
    });
  } catch (err) {
    next(err);
  }
}

module.exports = {
  getMyOrders,
  getOrderDetails,
};
