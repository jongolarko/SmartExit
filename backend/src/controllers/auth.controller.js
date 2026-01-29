const crypto = require("crypto");
const jwt = require("jsonwebtoken");
const pool = require("../config/db");
const otpService = require("../services/otp.service");
const logger = require("../utils/logger");
const { success, error } = require("../utils/response");

// Generate tokens
function generateTokens(user) {
  const accessToken = jwt.sign(
    { user_id: user.id, role: user.role },
    process.env.JWT_SECRET,
    { expiresIn: "15m" }
  );

  const refreshToken = jwt.sign(
    { user_id: user.id, type: "refresh" },
    process.env.JWT_REFRESH_SECRET || process.env.JWT_SECRET,
    { expiresIn: "7d" }
  );

  return { accessToken, refreshToken };
}

// POST /auth/register - Register new user and send OTP
async function register(req, res, next) {
  try {
    const { phone, name } = req.body;

    // Check if user already exists
    const existing = await pool.query(
      "SELECT id FROM users WHERE phone = $1",
      [phone]
    );

    if (existing.rows.length > 0) {
      return error(res, "Phone number already registered", 409);
    }

    // Check rate limit
    const canSend = await otpService.checkRateLimit(phone);
    if (!canSend) {
      return error(res, "Too many OTP requests. Try again later", 429);
    }

    // Generate and send OTP
    const otp = otpService.generateOTP();
    await otpService.storeOTP(phone, otp);
    await otpService.sendOTP(phone, otp);
    await otpService.logOTPRequest(phone);

    // Store pending registration
    await pool.query(
      `INSERT INTO pending_registrations (id, phone, name, created_at)
       VALUES ($1, $2, $3, NOW())
       ON CONFLICT (phone) DO UPDATE SET name = $2, created_at = NOW()`,
      [crypto.randomUUID(), phone, name]
    );

    logger.info(`Registration OTP sent to ${phone}`);

    return success(res, {
      message: "OTP sent to your phone",
      phone,
    });
  } catch (err) {
    next(err);
  }
}

// POST /auth/verify-otp - Verify OTP and complete registration
async function verifyOtp(req, res, next) {
  try {
    const { phone, otp, expected_role } = req.body;

    // Verify OTP
    const verification = await otpService.verifyOTP(phone, otp);
    if (!verification.valid) {
      return error(res, verification.error, 400);
    }

    // Check if this is a new registration
    const pending = await pool.query(
      "SELECT * FROM pending_registrations WHERE phone = $1",
      [phone]
    );

    let user;

    if (pending.rows.length > 0) {
      // Complete registration from pending
      const { name } = pending.rows[0];
      const userId = crypto.randomUUID();

      await pool.query(
        `INSERT INTO users (id, phone, name, role, created_at)
         VALUES ($1, $2, $3, 'customer', NOW())`,
        [userId, phone, name]
      );

      // Delete pending registration
      await pool.query(
        "DELETE FROM pending_registrations WHERE phone = $1",
        [phone]
      );

      user = { id: userId, phone, name, role: "customer" };
      logger.info(`New user registered: ${phone}`);
    } else {
      // Check if user exists
      const result = await pool.query(
        "SELECT id, phone, name, role FROM users WHERE phone = $1",
        [phone]
      );

      if (result.rows.length === 0) {
        // AUTO-REGISTER: Create new customer if expected_role is 'customer'
        if (expected_role === 'customer') {
          const userId = crypto.randomUUID();
          const userName = phone; // Use phone as name for auto-registered users

          await pool.query(
            `INSERT INTO users (id, phone, name, role, created_at)
             VALUES ($1, $2, $3, 'customer', NOW())`,
            [userId, phone, userName]
          );

          user = { id: userId, phone, name: userName, role: "customer" };
          logger.info(`New customer auto-registered: ${phone}`);
        } else {
          // Store app users must be pre-created by admin
          return error(res, "Account not found. Please contact admin for store access", 404);
        }
      } else {
        // Existing user login - validate role if expected_role is provided
        user = result.rows[0];

        if (expected_role && user.role !== expected_role) {
          return error(
            res,
            `This account is registered as ${user.role}. Please use the correct login option`,
            403
          );
        }

        logger.info(`User logged in: ${phone} (${user.role})`);
      }
    }

    // Generate tokens
    const { accessToken, refreshToken } = generateTokens(user);

    // Store refresh token
    await pool.query(
      `INSERT INTO refresh_tokens (id, user_id, token, expires_at, created_at)
       VALUES ($1, $2, $3, NOW() + INTERVAL '7 days', NOW())`,
      [crypto.randomUUID(), user.id, refreshToken]
    );

    return success(res, {
      message: "Authentication successful",
      token: accessToken,
      refresh_token: refreshToken,
      user: {
        id: user.id,
        name: user.name,
        phone: user.phone,
        role: user.role,
      },
    });
  } catch (err) {
    next(err);
  }
}

// POST /auth/send-otp - Send OTP for login/registration
async function sendOtp(req, res, next) {
  try {
    const { phone } = req.body;

    // Check rate limit
    const canSend = await otpService.checkRateLimit(phone);
    if (!canSend) {
      return error(res, "Too many OTP requests. Try again later", 429);
    }

    // Generate and send OTP (no need to check if user exists - auto-registration will handle it)
    const otp = otpService.generateOTP();
    await otpService.storeOTP(phone, otp);
    await otpService.sendOTP(phone, otp);
    await otpService.logOTPRequest(phone);

    logger.info(`OTP sent to ${phone}`);

    return success(res, {
      message: "OTP sent to your phone",
      phone,
    });
  } catch (err) {
    next(err);
  }
}

// POST /auth/refresh-token - Refresh access token
async function refreshToken(req, res, next) {
  try {
    const { refresh_token } = req.body;

    // Verify refresh token
    let decoded;
    try {
      decoded = jwt.verify(
        refresh_token,
        process.env.JWT_REFRESH_SECRET || process.env.JWT_SECRET
      );
    } catch (err) {
      return error(res, "Invalid refresh token", 401);
    }

    // Check if token exists in database
    const result = await pool.query(
      `SELECT rt.*, u.id, u.name, u.phone, u.role
       FROM refresh_tokens rt
       JOIN users u ON rt.user_id = u.id
       WHERE rt.token = $1 AND rt.expires_at > NOW()`,
      [refresh_token]
    );

    if (result.rows.length === 0) {
      return error(res, "Refresh token expired or revoked", 401);
    }

    const user = result.rows[0];

    // Generate new tokens
    const tokens = generateTokens({
      id: user.user_id,
      role: user.role,
    });

    // Delete old refresh token and create new one
    await pool.query("DELETE FROM refresh_tokens WHERE token = $1", [
      refresh_token,
    ]);

    await pool.query(
      `INSERT INTO refresh_tokens (id, user_id, token, expires_at, created_at)
       VALUES ($1, $2, $3, NOW() + INTERVAL '7 days', NOW())`,
      [crypto.randomUUID(), user.user_id, tokens.refreshToken]
    );

    return success(res, {
      token: tokens.accessToken,
      refresh_token: tokens.refreshToken,
    });
  } catch (err) {
    next(err);
  }
}

// POST /auth/logout - Revoke refresh token
async function logout(req, res, next) {
  try {
    const { refresh_token } = req.body;

    if (refresh_token) {
      await pool.query("DELETE FROM refresh_tokens WHERE token = $1", [
        refresh_token,
      ]);
    }

    // Also delete all tokens for this user if they want to logout from all devices
    if (req.body.all_devices && req.user) {
      await pool.query("DELETE FROM refresh_tokens WHERE user_id = $1", [
        req.user.user_id,
      ]);
    }

    return success(res, { message: "Logged out successfully" });
  } catch (err) {
    next(err);
  }
}

// GET /auth/me - Get current user profile
async function getProfile(req, res, next) {
  try {
    const result = await pool.query(
      "SELECT id, name, phone, role, created_at FROM users WHERE id = $1",
      [req.user.user_id]
    );

    if (result.rows.length === 0) {
      return error(res, "User not found", 404);
    }

    return success(res, { user: result.rows[0] });
  } catch (err) {
    next(err);
  }
}

module.exports = {
  register,
  verifyOtp,
  sendOtp,
  refreshToken,
  logout,
  getProfile,
};
