const pool = require("../config/db");
const { emitExitDecision, emitFraudAlert } = require("../config/socket");
const { success, error } = require("../utils/response");
const logger = require("../utils/logger");
const notificationService = require("../services/notification.service");

// POST /security/verify-qr - Verify exit QR code
async function verifyQR(req, res, next) {
  try {
    const { exit_token } = req.body;

    const result = await pool.query(
      `SELECT ga.*, u.id as user_id, u.name, u.phone, o.total_amount, o.id as order_id
       FROM gate_access ga
       JOIN users u ON ga.user_id = u.id
       JOIN orders o ON ga.order_id = o.id
       WHERE ga.exit_token = $1`,
      [exit_token]
    );

    if (result.rows.length === 0) {
      logger.warn(`Invalid exit token scanned: ${exit_token}`);
      return success(res, {
        valid: false,
        reason: "Token not found",
      });
    }

    const record = result.rows[0];

    // Check if already verified
    if (record.verified) {
      logger.warn(`Already used exit token: ${exit_token}`);
      return success(res, {
        valid: false,
        reason: "Token already used",
        previous_decision: record.allowed ? "allowed" : "denied",
      });
    }

    // Check if expired
    if (new Date(record.expires_at) < new Date()) {
      logger.warn(`Expired exit token: ${exit_token}`);

      // Emit fraud alert
      emitFraudAlert({
        type: "expired_token",
        user: { name: record.name, phone: record.phone },
        token: exit_token,
        expired_at: record.expires_at,
      });

      return success(res, {
        valid: false,
        reason: "Token expired",
        expired_at: record.expires_at,
      });
    }

    // Get order items for display
    const itemsRes = await pool.query(
      `SELECT oi.quantity, oi.price, p.name, p.barcode
       FROM order_items oi
       JOIN products p ON oi.product_id = p.id
       WHERE oi.order_id = $1`,
      [record.order_id]
    );

    logger.info(`Valid exit token verified: ${exit_token} for user ${record.name}`);

    return success(res, {
      valid: true,
      user: {
        id: record.user_id,
        name: record.name,
        phone: record.phone,
      },
      order: {
        id: record.order_id,
        amount: record.total_amount,
        items: itemsRes.rows,
      },
      expires_at: record.expires_at,
      exit_token,
    });
  } catch (err) {
    next(err);
  }
}

// POST /security/allow-exit - Allow or deny exit
async function allowExit(req, res, next) {
  try {
    const { exit_token, decision } = req.body;
    const securityUserId = req.user.user_id;

    // Get gate access record
    const result = await pool.query(
      `SELECT ga.*, u.id as customer_id
       FROM gate_access ga
       JOIN users u ON ga.user_id = u.id
       WHERE ga.exit_token = $1`,
      [exit_token]
    );

    if (result.rows.length === 0) {
      return error(res, "Exit token not found", 404);
    }

    const record = result.rows[0];

    if (record.verified) {
      return error(res, "Token already processed", 400);
    }

    // Update gate access
    await pool.query(
      `UPDATE gate_access
       SET verified = true,
           allowed = $1,
           verified_by = $2,
           verified_at = NOW()
       WHERE exit_token = $3`,
      [decision === "allow", securityUserId, exit_token]
    );

    logger.info(
      `Exit ${decision === "allow" ? "ALLOWED" : "DENIED"} for token ${exit_token} by security ${securityUserId}`
    );

    // Notify customer via realtime
    emitExitDecision(record.customer_id, {
      exit_token,
      decision,
      message:
        decision === "allow"
          ? "Exit approved! Please proceed."
          : "Exit denied. Please contact store staff.",
    });

    // Send push notification to customer
    if (decision === "allow") {
      notificationService.sendExitApprovedNotification(
        record.customer_id,
        exit_token
      );
    } else {
      notificationService.sendExitDeniedNotification(
        record.customer_id,
        exit_token,
        "Please contact store staff for assistance."
      );
    }

    return success(res, {
      message: `Exit ${decision === "allow" ? "allowed" : "denied"}`,
      exit_token,
      decision,
    });
  } catch (err) {
    next(err);
  }
}

// GET /security/pending - Get pending exit requests
async function getPendingExits(req, res, next) {
  try {
    const result = await pool.query(
      `SELECT ga.exit_token, ga.expires_at, ga.created_at,
              u.name, u.phone,
              o.total_amount, o.id as order_id
       FROM gate_access ga
       JOIN users u ON ga.user_id = u.id
       JOIN orders o ON ga.order_id = o.id
       WHERE ga.verified = false AND ga.expires_at > NOW()
       ORDER BY ga.created_at DESC`
    );

    return success(res, {
      pending_exits: result.rows,
      count: result.rows.length,
    });
  } catch (err) {
    next(err);
  }
}

// GET /security/history - Get verification history
async function getHistory(req, res, next) {
  try {
    const { page = 1, limit = 20 } = req.query;
    const offset = (page - 1) * limit;

    const result = await pool.query(
      `SELECT ga.exit_token, ga.verified, ga.allowed, ga.created_at, ga.verified_at,
              u.name as customer_name, u.phone as customer_phone,
              o.total_amount,
              s.name as verified_by_name
       FROM gate_access ga
       JOIN users u ON ga.user_id = u.id
       JOIN orders o ON ga.order_id = o.id
       LEFT JOIN users s ON ga.verified_by = s.id
       WHERE ga.verified = true
       ORDER BY ga.verified_at DESC
       LIMIT $1 OFFSET $2`,
      [limit, offset]
    );

    const countRes = await pool.query(
      "SELECT COUNT(*) FROM gate_access WHERE verified = true"
    );

    return success(res, {
      history: result.rows,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total: parseInt(countRes.rows[0].count),
      },
    });
  } catch (err) {
    next(err);
  }
}

module.exports = {
  verifyQR,
  allowExit,
  getPendingExits,
  getHistory,
};
