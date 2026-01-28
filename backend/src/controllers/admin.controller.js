const pool = require("../config/db");
const razorpay = require("../config/razorpay");
const { success, error, paginated } = require("../utils/response");
const inventoryService = require("../services/inventory.service");

// Helper function to log admin activity
async function logAdminActivity(adminId, action, entityType, entityId, details = null) {
  await pool.query(
    `INSERT INTO admin_activity_logs (admin_id, action, entity_type, entity_id, details)
     VALUES ($1, $2, $3, $4, $5)`,
    [adminId, action, entityType, entityId, details ? JSON.stringify(details) : null]
  );
}

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

// POST /admin/orders/:orderId/refund - Initiate Razorpay refund
async function refundOrder(req, res, next) {
  console.log('⚡ REFUND ENDPOINT HIT - Order ID:', req.params.orderId);
  try {
    const { orderId: id } = req.params;
    const { amount, reason } = req.body;
    const adminId = req.user.user_id;

    // Get order details
    const orderRes = await pool.query(
      `SELECT id, razorpay_payment_id, total_amount, status, user_id
       FROM orders WHERE id = $1`,
      [id]
    );

    if (orderRes.rows.length === 0) {
      return error(res, "Order not found", 404);
    }

    const order = orderRes.rows[0];

    if (order.status !== "paid") {
      return error(res, "Only paid orders can be refunded", 400);
    }

    if (!order.razorpay_payment_id) {
      return error(res, "No payment ID found for this order", 400);
    }

    // Determine refund amount (full or partial)
    const refundAmount = amount ? parseFloat(amount) : parseFloat(order.total_amount);

    if (refundAmount <= 0 || refundAmount > parseFloat(order.total_amount)) {
      return error(res, "Invalid refund amount", 400);
    }

    // Call Razorpay refund API
    const refund = await razorpay.payments.refund(order.razorpay_payment_id, {
      amount: Math.round(refundAmount * 100), // Convert to paise
      notes: {
        order_id: id,
        reason: reason || "Admin initiated refund",
      },
    });

    // Update order with refund details
    await pool.query(
      `UPDATE orders
       SET status = 'refunded',
           refund_id = $1,
           refund_amount = $2,
           refunded_at = NOW(),
           refund_reason = $3,
           updated_at = NOW()
       WHERE id = $4`,
      [refund.id, refundAmount, reason || null, id]
    );

    // Log admin activity
    await logAdminActivity(adminId, "refund_order", "order", id, {
      refund_id: refund.id,
      amount: refundAmount,
      reason: reason,
    });

    // Emit socket event for real-time notification
    const io = req.app.get("io");
    if (io) {
      io.to(`user:${order.user_id}`).emit("order:refunded", {
        order_id: id,
        refund_amount: refundAmount,
      });
    }

    return success(res, {
      message: "Refund processed successfully",
      refund: {
        id: refund.id,
        amount: refundAmount,
        status: refund.status,
      },
    });
  } catch (err) {
    if (err.error && err.error.description) {
      return error(res, `Razorpay error: ${err.error.description}`, 400);
    }
    next(err);
  }
}

// PUT /admin/orders/:orderId/cancel - Cancel unpaid order
async function cancelOrder(req, res, next) {
  try {
    const { orderId: id } = req.params;
    const { reason } = req.body;
    const adminId = req.user.user_id;

    // Get order details
    const orderRes = await pool.query(
      `SELECT id, status, user_id FROM orders WHERE id = $1`,
      [id]
    );

    if (orderRes.rows.length === 0) {
      return error(res, "Order not found", 404);
    }

    const order = orderRes.rows[0];

    if (order.status !== "created") {
      return error(res, "Only unpaid orders (status: created) can be cancelled", 400);
    }

    // Update order status
    await pool.query(
      `UPDATE orders SET status = 'cancelled', updated_at = NOW() WHERE id = $1`,
      [id]
    );

    // Log admin activity
    await logAdminActivity(adminId, "cancel_order", "order", id, {
      reason: reason || null,
    });

    // Emit socket event
    const io = req.app.get("io");
    if (io) {
      io.to(`user:${order.user_id}`).emit("order:cancelled", {
        order_id: id,
        reason: reason,
      });
    }

    return success(res, { message: "Order cancelled successfully" });
  } catch (err) {
    next(err);
  }
}

// GET /admin/users/:id - Get user details with order stats
async function getUserDetails(req, res, next) {
  try {
    const { id } = req.params;

    // Get user details
    const userRes = await pool.query(
      `SELECT id, name, phone, role, created_at FROM users WHERE id = $1`,
      [id]
    );

    if (userRes.rows.length === 0) {
      return error(res, "User not found", 404);
    }

    // Get order statistics
    const statsRes = await pool.query(
      `SELECT
         COUNT(*) as total_orders,
         COALESCE(SUM(CASE WHEN status = 'paid' THEN total_amount ELSE 0 END), 0) as total_spent,
         COALESCE(SUM(CASE WHEN status = 'refunded' THEN refund_amount ELSE 0 END), 0) as total_refunded
       FROM orders WHERE user_id = $1`,
      [id]
    );

    return success(res, {
      user: userRes.rows[0],
      stats: {
        total_orders: parseInt(statsRes.rows[0].total_orders),
        total_spent: parseFloat(statsRes.rows[0].total_spent),
        total_refunded: parseFloat(statsRes.rows[0].total_refunded),
      },
    });
  } catch (err) {
    next(err);
  }
}

// PUT /admin/users/:id/role - Update user role
async function updateUserRole(req, res, next) {
  try {
    const { id } = req.params;
    const { role } = req.body;
    const adminId = req.user.user_id;

    // Validate role
    const validRoles = ["customer", "security", "admin"];
    if (!validRoles.includes(role)) {
      return error(res, `Invalid role. Must be one of: ${validRoles.join(", ")}`, 400);
    }

    // Check if user exists and get current role
    const userRes = await pool.query(
      `SELECT id, name, role FROM users WHERE id = $1`,
      [id]
    );

    if (userRes.rows.length === 0) {
      return error(res, "User not found", 404);
    }

    const oldRole = userRes.rows[0].role;

    // Prevent admin from demoting themselves
    if (id === adminId && role !== "admin") {
      return error(res, "Cannot change your own role", 400);
    }

    // Update user role
    await pool.query(
      `UPDATE users SET role = $1, updated_at = NOW() WHERE id = $2`,
      [role, id]
    );

    // Invalidate user's refresh tokens (force re-login)
    await pool.query(`DELETE FROM refresh_tokens WHERE user_id = $1`, [id]);

    // Log admin activity
    await logAdminActivity(adminId, "update_role", "user", id, {
      old_role: oldRole,
      new_role: role,
    });

    return success(res, {
      message: "User role updated successfully",
      user: {
        id,
        name: userRes.rows[0].name,
        role,
      },
    });
  } catch (err) {
    next(err);
  }
}

// GET /admin/users/:id/orders - Get user's order history
async function getUserOrders(req, res, next) {
  try {
    const { id } = req.params;
    const { page = 1, limit = 20 } = req.query;
    const offset = (page - 1) * limit;

    // Check if user exists
    const userRes = await pool.query(`SELECT id FROM users WHERE id = $1`, [id]);

    if (userRes.rows.length === 0) {
      return error(res, "User not found", 404);
    }

    // Get orders
    const ordersRes = await pool.query(
      `SELECT id, total_amount, status, created_at, paid_at,
              razorpay_order_id, razorpay_payment_id,
              refund_id, refund_amount, refunded_at
       FROM orders
       WHERE user_id = $1
       ORDER BY created_at DESC
       LIMIT $2 OFFSET $3`,
      [id, limit, offset]
    );

    // Get total count
    const countRes = await pool.query(
      `SELECT COUNT(*) FROM orders WHERE user_id = $1`,
      [id]
    );

    return paginated(
      res,
      ordersRes.rows,
      parseInt(page),
      parseInt(limit),
      parseInt(countRes.rows[0].count)
    );
  } catch (err) {
    next(err);
  }
}

// ==================== ANALYTICS ENDPOINTS ====================

// GET /admin/analytics/revenue - Revenue chart data with date range
async function getRevenueChart(req, res, next) {
  try {
    const { range = '7d', startDate, endDate } = req.query;

    let start, end, previousStart, previousEnd;
    const now = new Date();

    if (startDate && endDate) {
      start = new Date(startDate);
      end = new Date(endDate);
      const diff = end - start;
      previousStart = new Date(start - diff);
      previousEnd = start;
    } else {
      const days = range === '7d' ? 7 : range === '30d' ? 30 : 90;
      end = now;
      start = new Date(now - days * 24 * 60 * 60 * 1000);
      previousEnd = start;
      previousStart = new Date(start - days * 24 * 60 * 60 * 1000);
    }

    // Current period data
    const currentData = await pool.query(
      `SELECT DATE(paid_at) as date, COUNT(*) as orders, SUM(total_amount) as revenue
       FROM orders
       WHERE status = 'paid' AND paid_at >= $1 AND paid_at < $2
       GROUP BY DATE(paid_at)
       ORDER BY date`,
      [start, end]
    );

    // Previous period for comparison
    const previousData = await pool.query(
      `SELECT SUM(total_amount) as total FROM orders
       WHERE status = 'paid' AND paid_at >= $1 AND paid_at < $2`,
      [previousStart, previousEnd]
    );

    const currentTotal = currentData.rows.reduce((sum, row) => sum + parseFloat(row.revenue), 0);
    const previousTotal = parseFloat(previousData.rows[0]?.total || 0);
    const percentChange = previousTotal > 0
      ? ((currentTotal - previousTotal) / previousTotal * 100).toFixed(1)
      : 0;

    return success(res, {
      data: currentData.rows,
      comparison: {
        current: currentTotal,
        previous: previousTotal,
        percentChange: parseFloat(percentChange)
      }
    });
  } catch (err) {
    next(err);
  }
}

// GET /admin/analytics/kpi-trends - Today vs Yesterday KPIs
async function getKpiTrends(req, res, next) {
  try {
    const today = new Date();
    const todayStart = new Date(today.setHours(0, 0, 0, 0));
    const yesterdayStart = new Date(todayStart - 24 * 60 * 60 * 1000);

    // Today's KPIs
    const todayKpis = await pool.query(
      `SELECT
        COUNT(*) as orders,
        COALESCE(SUM(total_amount), 0) as revenue,
        (SELECT COUNT(*) FROM users WHERE created_at >= $1) as new_users
       FROM orders
       WHERE status = 'paid' AND paid_at >= $1`,
      [todayStart]
    );

    // Yesterday's KPIs
    const yesterdayKpis = await pool.query(
      `SELECT
        COUNT(*) as orders,
        COALESCE(SUM(total_amount), 0) as revenue,
        (SELECT COUNT(*) FROM users WHERE created_at >= $1 AND created_at < $2) as new_users
       FROM orders
       WHERE status = 'paid' AND paid_at >= $1 AND paid_at < $2`,
      [yesterdayStart, todayStart]
    );

    const today_data = todayKpis.rows[0];
    const yesterday_data = yesterdayKpis.rows[0];

    const calculate_change = (current, previous) => {
      if (previous === 0) return current > 0 ? 100 : 0;
      return ((current - previous) / previous * 100).toFixed(1);
    };

    return success(res, {
      revenue: {
        current: parseFloat(today_data.revenue),
        previous: parseFloat(yesterday_data.revenue),
        change: parseFloat(calculate_change(today_data.revenue, yesterday_data.revenue))
      },
      orders: {
        current: parseInt(today_data.orders),
        previous: parseInt(yesterday_data.orders),
        change: parseFloat(calculate_change(today_data.orders, yesterday_data.orders))
      },
      users: {
        current: parseInt(today_data.new_users),
        previous: parseInt(yesterday_data.new_users),
        change: parseFloat(calculate_change(today_data.new_users, yesterday_data.new_users))
      }
    });
  } catch (err) {
    next(err);
  }
}

// GET /admin/analytics/sales/summary - Daily/Weekly/Monthly aggregation
async function getSalesSummary(req, res, next) {
  try {
    const { period = 'daily', startDate, endDate } = req.query;

    const groupBy = {
      'daily': 'DATE(paid_at)',
      'weekly': 'DATE_TRUNC(\'week\', paid_at)',
      'monthly': 'DATE_TRUNC(\'month\', paid_at)'
    }[period];

    const data = await pool.query(
      `SELECT
        ${groupBy} as period,
        COUNT(*) as order_count,
        SUM(total_amount) as revenue,
        AVG(total_amount) as avg_order_value
       FROM orders
       WHERE status = 'paid'
         AND paid_at >= $1
         AND paid_at < $2
       GROUP BY ${groupBy}
       ORDER BY period DESC`,
      [startDate || new Date(Date.now() - 30 * 24 * 60 * 60 * 1000), endDate || new Date()]
    );

    return success(res, { data: data.rows });
  } catch (err) {
    next(err);
  }
}

// GET /admin/analytics/sales/peak-hours - Hourly breakdown
async function getPeakHours(req, res, next) {
  try {
    const data = await pool.query(
      `SELECT
        EXTRACT(HOUR FROM paid_at) as hour,
        COUNT(*) as order_count,
        SUM(total_amount) as revenue
       FROM orders
       WHERE status = 'paid'
         AND paid_at >= NOW() - INTERVAL '30 days'
       GROUP BY EXTRACT(HOUR FROM paid_at)
       ORDER BY hour`
    );

    return success(res, { data: data.rows });
  } catch (err) {
    next(err);
  }
}

// GET /admin/analytics/sales/refund-rate - Refund statistics
async function getRefundRate(req, res, next) {
  try {
    const stats = await pool.query(
      `SELECT
        COUNT(CASE WHEN status = 'paid' THEN 1 END) as paid_orders,
        COUNT(CASE WHEN status = 'refunded' THEN 1 END) as refunded_orders,
        SUM(CASE WHEN status = 'refunded' THEN refund_amount ELSE 0 END) as total_refunded
       FROM orders
       WHERE paid_at >= NOW() - INTERVAL '30 days'`
    );

    const data = stats.rows[0];
    const refundRate = data.paid_orders > 0
      ? (data.refunded_orders / data.paid_orders * 100).toFixed(2)
      : 0;

    return success(res, {
      paidOrders: parseInt(data.paid_orders),
      refundedOrders: parseInt(data.refunded_orders),
      totalRefunded: parseFloat(data.total_refunded),
      refundRate: parseFloat(refundRate)
    });
  } catch (err) {
    next(err);
  }
}

// GET /admin/analytics/products/top - Top 10 by revenue or quantity
async function getTopProducts(req, res, next) {
  try {
    const { metric = 'revenue', limit = 10 } = req.query;

    const orderBy = metric === 'revenue'
      ? 'SUM(oi.price * oi.quantity)'
      : 'SUM(oi.quantity)';

    const data = await pool.query(
      `SELECT
        p.id, p.name, p.barcode,
        COUNT(DISTINCT o.id) as order_count,
        SUM(oi.quantity) as units_sold,
        SUM(oi.price * oi.quantity) as revenue
       FROM products p
       JOIN order_items oi ON p.id = oi.product_id
       JOIN orders o ON oi.order_id = o.id
       WHERE o.status = 'paid'
         AND o.paid_at >= NOW() - INTERVAL '30 days'
       GROUP BY p.id, p.name, p.barcode
       ORDER BY ${orderBy} DESC
       LIMIT $1`,
      [limit]
    );

    return success(res, { data: data.rows });
  } catch (err) {
    next(err);
  }
}

// GET /admin/analytics/products/slow-movers - Products with low sales
async function getSlowMovers(req, res, next) {
  try {
    const data = await pool.query(
      `SELECT
        p.id, p.name, p.barcode, p.stock,
        COALESCE(SUM(oi.quantity), 0) as units_sold,
        EXTRACT(DAYS FROM NOW() - MAX(o.paid_at)) as days_since_last_sale
       FROM products p
       LEFT JOIN order_items oi ON p.id = oi.product_id
       LEFT JOIN orders o ON oi.order_id = o.id AND o.status = 'paid'
       WHERE p.stock > 0
       GROUP BY p.id, p.name, p.barcode, p.stock
       HAVING COALESCE(SUM(oi.quantity), 0) < 5
       ORDER BY days_since_last_sale DESC
       LIMIT 20`
    );

    return success(res, { data: data.rows });
  } catch (err) {
    next(err);
  }
}

// GET /admin/analytics/products/turnover - Stock turnover rate
async function getStockTurnover(req, res, next) {
  try {
    const data = await pool.query(
      `SELECT
        p.id,
        p.name,
        p.stock as current_stock,
        COALESCE(SUM(oi.quantity), 0) as total_sold,
        CASE
          WHEN p.stock > 0 THEN (COALESCE(SUM(oi.quantity), 0)::float / p.stock)
          ELSE 0
        END as turnover_rate
       FROM products p
       LEFT JOIN order_items oi ON p.id = oi.product_id
       LEFT JOIN orders o ON oi.order_id = o.id
         AND o.status = 'paid'
         AND o.paid_at >= NOW() - INTERVAL '30 days'
       WHERE p.stock IS NOT NULL
       GROUP BY p.id, p.name, p.stock
       ORDER BY turnover_rate DESC
       LIMIT 20`
    );

    return success(res, { data: data.rows });
  } catch (err) {
    next(err);
  }
}

// GET /admin/analytics/customers/acquisition - New customers over time
async function getCustomerAcquisition(req, res, next) {
  try {
    const { range = '30d' } = req.query;
    const days = range === '7d' ? 7 : range === '30d' ? 30 : 90;

    const data = await pool.query(
      `SELECT
        DATE(created_at) as date,
        COUNT(*) as new_customers
       FROM users
       WHERE role = 'customer'
         AND created_at >= NOW() - INTERVAL '${days} days'
       GROUP BY DATE(created_at)
       ORDER BY date`
    );

    return success(res, { data: data.rows });
  } catch (err) {
    next(err);
  }
}

// GET /admin/analytics/customers/repeat-rate - Repeat purchase percentage
async function getRepeatRate(req, res, next) {
  try {
    const stats = await pool.query(
      `WITH customer_order_counts AS (
        SELECT user_id, COUNT(*) as order_count
        FROM orders
        WHERE status = 'paid'
        GROUP BY user_id
      )
      SELECT
        COUNT(*) as total_customers,
        COUNT(CASE WHEN order_count > 1 THEN 1 END) as repeat_customers
      FROM customer_order_counts`
    );

    const data = stats.rows[0];
    const repeatRate = data.total_customers > 0
      ? (data.repeat_customers / data.total_customers * 100).toFixed(2)
      : 0;

    return success(res, {
      totalCustomers: parseInt(data.total_customers),
      repeatCustomers: parseInt(data.repeat_customers),
      repeatRate: parseFloat(repeatRate)
    });
  } catch (err) {
    next(err);
  }
}

// GET /admin/analytics/customers/lifetime-value - CLV ranking
async function getCustomerLifetimeValue(req, res, next) {
  try {
    const data = await pool.query(
      `SELECT
        u.id, u.phone as phone_number,
        COUNT(o.id) as order_count,
        SUM(o.total_amount) as lifetime_value,
        MAX(o.paid_at) as last_purchase
       FROM users u
       JOIN orders o ON u.id = o.user_id
       WHERE o.status = 'paid' AND u.role = 'customer'
       GROUP BY u.id, u.phone
       ORDER BY lifetime_value DESC
       LIMIT 50`
    );

    return success(res, { data: data.rows });
  } catch (err) {
    next(err);
  }
}

// GET /admin/analytics/customers/segmentation - Customer segments
async function getCustomerSegmentation(req, res, next) {
  try {
    const data = await pool.query(
      `WITH customer_stats AS (
        SELECT
          user_id,
          COUNT(*) as order_count,
          SUM(total_amount) as total_spent
        FROM orders
        WHERE status = 'paid'
        GROUP BY user_id
      )
      SELECT
        CASE
          WHEN order_count >= 10 THEN 'VIP'
          WHEN order_count >= 5 THEN 'Loyal'
          WHEN order_count >= 2 THEN 'Regular'
          ELSE 'New'
        END as segment,
        COUNT(*) as customer_count,
        AVG(total_spent) as avg_spent
      FROM customer_stats
      GROUP BY segment
      ORDER BY avg_spent DESC`
    );

    return success(res, { data: data.rows });
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
  refundOrder,
  cancelOrder,
  getUserDetails,
  updateUserRole,
  getUserOrders,
  // Analytics
  getRevenueChart,
  getKpiTrends,
  getSalesSummary,
  getPeakHours,
  getRefundRate,
  getTopProducts,
  getSlowMovers,
  getStockTurnover,
  getCustomerAcquisition,
  getRepeatRate,
  getCustomerLifetimeValue,
  getCustomerSegmentation,
};
