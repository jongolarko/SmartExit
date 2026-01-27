const crypto = require("crypto");
const pool = require("../config/db");
const { emitExitRequest } = require("../config/socket");
const { success, error } = require("../utils/response");
const logger = require("../utils/logger");

// Token expiry time in minutes
const EXIT_TOKEN_EXPIRY_MINUTES = 5;

// POST /exit/generate - Generate exit QR token
async function generateExitToken(req, res, next) {
  try {
    const userId = req.user.user_id;
    const { order_id } = req.body;

    // Verify order belongs to user and is paid
    const orderRes = await pool.query(
      `SELECT o.*, u.name, u.phone
       FROM orders o
       JOIN users u ON o.user_id = u.id
       WHERE o.id = $1 AND o.user_id = $2`,
      [order_id, userId]
    );

    if (orderRes.rows.length === 0) {
      return error(res, "Order not found", 404);
    }

    const order = orderRes.rows[0];

    if (order.status !== "paid") {
      return error(res, "Order not paid", 400);
    }

    // Check if there's already an active exit token for this order
    const existingToken = await pool.query(
      `SELECT * FROM gate_access
       WHERE order_id = $1 AND verified = false AND expires_at > NOW()`,
      [order_id]
    );

    if (existingToken.rows.length > 0) {
      // Return existing token
      const existing = existingToken.rows[0];
      return success(res, {
        exit_token: existing.exit_token,
        expires_at: existing.expires_at,
        message: "Using existing token",
      });
    }

    // Generate new exit token
    const exitToken = "EX-" + crypto.randomBytes(8).toString("hex").toUpperCase();
    const expiresAt = new Date(Date.now() + EXIT_TOKEN_EXPIRY_MINUTES * 60 * 1000);

    await pool.query(
      `INSERT INTO gate_access (id, user_id, order_id, exit_token, expires_at, created_at)
       VALUES ($1, $2, $3, $4, $5, NOW())`,
      [crypto.randomUUID(), userId, order_id, exitToken, expiresAt]
    );

    logger.info(`Exit token generated for order ${order_id}: ${exitToken}`);

    // Notify security personnel
    emitExitRequest({
      user: { name: order.name, phone: order.phone },
      order: { id: order_id, amount: order.total_amount },
      exit_token: exitToken,
      expires_at: expiresAt,
    });

    return success(res, {
      exit_token: exitToken,
      expires_at: expiresAt,
      message: "Exit token generated",
    });
  } catch (err) {
    next(err);
  }
}

// GET /exit/status/:token - Check exit token status
async function getExitStatus(req, res, next) {
  try {
    const { token } = req.params;
    const userId = req.user.user_id;

    const result = await pool.query(
      `SELECT ga.*, o.total_amount
       FROM gate_access ga
       JOIN orders o ON ga.order_id = o.id
       WHERE ga.exit_token = $1 AND ga.user_id = $2`,
      [token, userId]
    );

    if (result.rows.length === 0) {
      return error(res, "Exit token not found", 404);
    }

    const record = result.rows[0];
    const isExpired = new Date(record.expires_at) < new Date();

    return success(res, {
      exit_token: record.exit_token,
      status: record.verified
        ? record.allowed
          ? "approved"
          : "denied"
        : isExpired
        ? "expired"
        : "pending",
      verified: record.verified,
      allowed: record.allowed,
      expires_at: record.expires_at,
      order_amount: record.total_amount,
    });
  } catch (err) {
    next(err);
  }
}

module.exports = {
  generateExitToken,
  getExitStatus,
};
