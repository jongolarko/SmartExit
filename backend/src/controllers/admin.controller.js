const pool = require("../config/db");
const { success, error, paginated } = require("../utils/response");
const inventoryService = require("../services/inventory.service");

// GET /admin/dashboard - Dashboard statistics
async function getDashboard(req, res, next) {
  try {
    // Total revenue
    const revenueRes = await pool.query(
      "SELECT COALESCE(SUM(total_amount), 0) AS total FROM orders WHERE status = 'paid'"
    );

    // Today's revenue
    const todayRevenueRes = await pool.query(
      `SELECT COALESCE(SUM(total_amount), 0) AS total
       FROM orders
       WHERE status = 'paid' AND DATE(paid_at) = CURRENT_DATE`
    );

    // Total users
    const usersRes = await pool.query("SELECT COUNT(*) FROM users");

    // Today's new users
    const newUsersRes = await pool.query(
      "SELECT COUNT(*) FROM users WHERE DATE(created_at) = CURRENT_DATE"
    );

    // Total orders
    const ordersRes = await pool.query(
      "SELECT COUNT(*) FROM orders WHERE status = 'paid'"
    );

    // Today's orders
    const todayOrdersRes = await pool.query(
      `SELECT COUNT(*) FROM orders
       WHERE status = 'paid' AND DATE(paid_at) = CURRENT_DATE`
    );

    // Fraud alerts (unverified expired tokens)
    const fraudRes = await pool.query(
      `SELECT COUNT(*) FROM gate_access
       WHERE verified = false AND expires_at < NOW()`
    );

    // Pending exits
    const pendingRes = await pool.query(
      `SELECT COUNT(*) FROM gate_access
       WHERE verified = false AND expires_at > NOW()`
    );

    // Recent activity
    const recentOrdersRes = await pool.query(
      `SELECT o.id, o.total_amount, o.status, o.created_at, u.name
       FROM orders o
       JOIN users u ON o.user_id = u.id
       ORDER BY o.created_at DESC LIMIT 5`
    );

    return success(res, {
      revenue: {
        total: parseFloat(revenueRes.rows[0].total),
        today: parseFloat(todayRevenueRes.rows[0].total),
      },
      users: {
        total: parseInt(usersRes.rows[0].count),
        today: parseInt(newUsersRes.rows[0].count),
      },
      orders: {
        total: parseInt(ordersRes.rows[0].count),
        today: parseInt(todayOrdersRes.rows[0].count),
      },
      alerts: {
        fraud: parseInt(fraudRes.rows[0].count),
        pending_exits: parseInt(pendingRes.rows[0].count),
      },
      recent_orders: recentOrdersRes.rows,
    });
  } catch (err) {
    next(err);
  }
}

// GET /admin/orders - List all orders
async function getOrders(req, res, next) {
  try {
    const { page = 1, limit = 20, status } = req.query;
    const offset = (page - 1) * limit;

    let query = `
      SELECT o.id, o.total_amount, o.status, o.created_at, o.paid_at,
             o.razorpay_order_id, o.razorpay_payment_id,
             u.id as user_id, u.name, u.phone
      FROM orders o
      JOIN users u ON o.user_id = u.id
    `;

    const params = [];

    if (status) {
      query += " WHERE o.status = $1";
      params.push(status);
    }

    query += ` ORDER BY o.created_at DESC LIMIT $${params.length + 1} OFFSET $${params.length + 2}`;
    params.push(limit, offset);

    const result = await pool.query(query, params);

    // Get total count
    let countQuery = "SELECT COUNT(*) FROM orders";
    const countParams = [];
    if (status) {
      countQuery += " WHERE status = $1";
      countParams.push(status);
    }
    const countRes = await pool.query(countQuery, countParams);

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

// GET /admin/orders/:id - Get order details
async function getOrderDetails(req, res, next) {
  try {
    const { id } = req.params;

    const orderRes = await pool.query(
      `SELECT o.*, u.name, u.phone
       FROM orders o
       JOIN users u ON o.user_id = u.id
       WHERE o.id = $1`,
      [id]
    );

    if (orderRes.rows.length === 0) {
      return error(res, "Order not found", 404);
    }

    const itemsRes = await pool.query(
      `SELECT oi.quantity, oi.price, p.name, p.barcode
       FROM order_items oi
       JOIN products p ON oi.product_id = p.id
       WHERE oi.order_id = $1`,
      [id]
    );

    const exitRes = await pool.query(
      `SELECT exit_token, verified, allowed, expires_at, verified_at
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

// GET /admin/users - List all users
async function getUsers(req, res, next) {
  try {
    const { page = 1, limit = 20, role } = req.query;
    const offset = (page - 1) * limit;

    let query = `
      SELECT id, name, phone, role, created_at
      FROM users
    `;

    const params = [];

    if (role) {
      query += " WHERE role = $1";
      params.push(role);
    }

    query += ` ORDER BY created_at DESC LIMIT $${params.length + 1} OFFSET $${params.length + 2}`;
    params.push(limit, offset);

    const result = await pool.query(query, params);

    // Get total count
    let countQuery = "SELECT COUNT(*) FROM users";
    const countParams = [];
    if (role) {
      countQuery += " WHERE role = $1";
      countParams.push(role);
    }
    const countRes = await pool.query(countQuery, countParams);

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

// GET /admin/security-logs - Get security logs
async function getSecurityLogs(req, res, next) {
  try {
    const { page = 1, limit = 20 } = req.query;
    const offset = (page - 1) * limit;

    const result = await pool.query(
      `SELECT ga.exit_token, ga.verified, ga.allowed, ga.expires_at,
              ga.created_at, ga.verified_at,
              u.name as customer_name, u.phone as customer_phone,
              o.total_amount,
              s.name as security_name
       FROM gate_access ga
       JOIN users u ON ga.user_id = u.id
       JOIN orders o ON ga.order_id = o.id
       LEFT JOIN users s ON ga.verified_by = s.id
       ORDER BY ga.created_at DESC
       LIMIT $1 OFFSET $2`,
      [limit, offset]
    );

    const countRes = await pool.query("SELECT COUNT(*) FROM gate_access");

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

// GET /admin/products - List all products
async function getProducts(req, res, next) {
  try {
    const { page = 1, limit = 20, search } = req.query;
    const offset = (page - 1) * limit;

    let query = `SELECT * FROM products`;
    const params = [];

    if (search) {
      query += ` WHERE name ILIKE $1 OR barcode ILIKE $1`;
      params.push(`%${search}%`);
    }

    query += ` ORDER BY name ASC LIMIT $${params.length + 1} OFFSET $${params.length + 2}`;
    params.push(limit, offset);

    const result = await pool.query(query, params);

    let countQuery = "SELECT COUNT(*) FROM products";
    const countParams = [];
    if (search) {
      countQuery += ` WHERE name ILIKE $1 OR barcode ILIKE $1`;
      countParams.push(`%${search}%`);
    }
    const countRes = await pool.query(countQuery, countParams);

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

// POST /admin/products - Create product
async function createProduct(req, res, next) {
  try {
    const { barcode, name, price, description, stock, image_url } = req.body;

    const result = await pool.query(
      `INSERT INTO products (id, barcode, name, price, description, stock, image_url, created_at)
       VALUES ($1, $2, $3, $4, $5, $6, $7, NOW())
       RETURNING *`,
      [
        require("crypto").randomUUID(),
        barcode,
        name,
        price,
        description || null,
        stock || null,
        image_url || null,
      ]
    );

    return success(res, { product: result.rows[0] }, 201);
  } catch (err) {
    if (err.code === "23505") {
      return error(res, "Product with this barcode already exists", 409);
    }
    next(err);
  }
}

// PUT /admin/products/:id - Update product
async function updateProduct(req, res, next) {
  try {
    const { id } = req.params;
    const { name, price, description, stock, image_url } = req.body;

    const result = await pool.query(
      `UPDATE products
       SET name = COALESCE($1, name),
           price = COALESCE($2, price),
           description = COALESCE($3, description),
           stock = COALESCE($4, stock),
           image_url = COALESCE($5, image_url),
           updated_at = NOW()
       WHERE id = $6
       RETURNING *`,
      [name, price, description, stock, image_url, id]
    );

    if (result.rows.length === 0) {
      return error(res, "Product not found", 404);
    }

    return success(res, { product: result.rows[0] });
  } catch (err) {
    next(err);
  }
}

// POST /admin/products/:id/stock - Adjust stock with audit logging
async function adjustStock(req, res, next) {
  try {
    const { id } = req.params;
    const { quantity, change_type, reason } = req.body;
    const userId = req.user.user_id;

    // Validate change_type
    const validTypes = ["adjustment", "receipt", "damage", "return", "correction"];
    if (!validTypes.includes(change_type)) {
      return error(res, `Invalid change type. Must be one of: ${validTypes.join(", ")}`, 400);
    }

    if (typeof quantity !== "number" || quantity === 0) {
      return error(res, "Quantity must be a non-zero number", 400);
    }

    const result = await inventoryService.adjustStock(
      id,
      quantity,
      change_type,
      reason || null,
      userId
    );

    if (!result.success) {
      return error(res, result.error, 400);
    }

    return success(res, { product: result.product });
  } catch (err) {
    next(err);
  }
}

// DELETE /admin/products/:id - Soft delete product
async function deleteProduct(req, res, next) {
  try {
    const { id } = req.params;

    // Check if product exists
    const productRes = await pool.query(
      "SELECT id, name FROM products WHERE id = $1",
      [id]
    );

    if (productRes.rows.length === 0) {
      return error(res, "Product not found", 404);
    }

    // Check if product has been used in any orders
    const ordersRes = await pool.query(
      "SELECT COUNT(*) FROM order_items WHERE product_id = $1",
      [id]
    );

    if (parseInt(ordersRes.rows[0].count) > 0) {
      // Soft delete - set stock to 0 and mark as inactive
      await pool.query(
        "UPDATE products SET stock = 0, updated_at = NOW() WHERE id = $1",
        [id]
      );
      return success(res, {
        message: "Product deactivated (has order history)",
        soft_deleted: true,
      });
    }

    // Hard delete if no order history
    await pool.query("DELETE FROM products WHERE id = $1", [id]);

    return success(res, {
      message: "Product deleted successfully",
      soft_deleted: false,
    });
  } catch (err) {
    next(err);
  }
}

// GET /admin/inventory/low-stock - Get products below reorder level
async function getLowStockProducts(req, res, next) {
  try {
    const products = await inventoryService.getLowStockProducts();
    const summary = await inventoryService.getStockSummary();

    return success(res, {
      products,
      summary: {
        low_stock_count: parseInt(summary.low_stock_count),
        out_of_stock_count: parseInt(summary.out_of_stock_count),
        healthy_stock_count: parseInt(summary.healthy_stock_count),
        total_products: parseInt(summary.total_products),
        total_inventory_value: parseFloat(summary.total_inventory_value),
      },
    });
  } catch (err) {
    next(err);
  }
}

// GET /admin/inventory/report - Get stock movement report
async function getInventoryReport(req, res, next) {
  try {
    const { start_date, end_date, product_id } = req.query;

    // Default to last 30 days if no dates provided
    const endDate = end_date ? new Date(end_date) : new Date();
    const startDate = start_date
      ? new Date(start_date)
      : new Date(endDate.getTime() - 30 * 24 * 60 * 60 * 1000);

    const movements = await inventoryService.getStockReport(
      startDate,
      endDate,
      product_id || null
    );

    // Calculate summary statistics
    const summary = movements.reduce(
      (acc, m) => {
        if (m.change_type === "sale") {
          acc.total_sold += Math.abs(m.quantity_change);
        } else if (m.change_type === "receipt") {
          acc.total_received += m.quantity_change;
        } else if (m.change_type === "damage") {
          acc.total_damaged += Math.abs(m.quantity_change);
        } else if (m.change_type === "return") {
          acc.total_returned += m.quantity_change;
        }
        return acc;
      },
      { total_sold: 0, total_received: 0, total_damaged: 0, total_returned: 0 }
    );

    return success(res, {
      movements,
      summary,
      date_range: {
        start: startDate.toISOString(),
        end: endDate.toISOString(),
      },
    });
  } catch (err) {
    next(err);
  }
}

// GET /admin/products/:id/history - Get stock audit history for a product
async function getProductHistory(req, res, next) {
  try {
    const { id } = req.params;
    const { limit = 50 } = req.query;

    // Verify product exists
    const productRes = await pool.query(
      "SELECT id, name, barcode, stock, reorder_level FROM products WHERE id = $1",
      [id]
    );

    if (productRes.rows.length === 0) {
      return error(res, "Product not found", 404);
    }

    const history = await inventoryService.getProductAuditHistory(
      id,
      parseInt(limit)
    );

    return success(res, {
      product: productRes.rows[0],
      history,
    });
  } catch (err) {
    next(err);
  }
}

module.exports = {
  getDashboard,
  getOrders,
  getOrderDetails,
  getUsers,
  getSecurityLogs,
  getProducts,
  createProduct,
  updateProduct,
  adjustStock,
  deleteProduct,
  getLowStockProducts,
  getInventoryReport,
  getProductHistory,
};
