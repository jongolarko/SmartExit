const pool = require("../config/db");
const { success, error, paginated } = require("../utils/response");

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

module.exports = {
  getDashboard,
  getOrders,
  getOrderDetails,
  getUsers,
  getSecurityLogs,
  getProducts,
  createProduct,
  updateProduct,
};
