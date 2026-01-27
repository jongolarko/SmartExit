const crypto = require("crypto");
const pool = require("../config/db");
const logger = require("../utils/logger");

// OTP expiry time in minutes
const OTP_EXPIRY_MINUTES = 5;

// Generate a 6-digit OTP
function generateOTP() {
  return Math.floor(100000 + Math.random() * 900000).toString();
}

// Hash OTP for storage
function hashOTP(otp) {
  return crypto.createHash("sha256").update(otp).digest("hex");
}

// Store OTP in database
async function storeOTP(phone, otp) {
  const hashedOTP = hashOTP(otp);
  const expiresAt = new Date(Date.now() + OTP_EXPIRY_MINUTES * 60 * 1000);

  // Delete any existing OTP for this phone
  await pool.query("DELETE FROM otp_tokens WHERE phone = $1", [phone]);

  // Insert new OTP
  await pool.query(
    `INSERT INTO otp_tokens (id, phone, otp_hash, expires_at, attempts)
     VALUES ($1, $2, $3, $4, 0)`,
    [crypto.randomUUID(), phone, hashedOTP, expiresAt]
  );

  return expiresAt;
}

// Verify OTP
async function verifyOTP(phone, otp) {
  const result = await pool.query(
    `SELECT * FROM otp_tokens WHERE phone = $1`,
    [phone]
  );

  if (result.rows.length === 0) {
    return { valid: false, error: "OTP not found or expired" };
  }

  const record = result.rows[0];

  // Check if expired
  if (new Date(record.expires_at) < new Date()) {
    await pool.query("DELETE FROM otp_tokens WHERE phone = $1", [phone]);
    return { valid: false, error: "OTP expired" };
  }

  // Check attempts (max 3)
  if (record.attempts >= 3) {
    await pool.query("DELETE FROM otp_tokens WHERE phone = $1", [phone]);
    return { valid: false, error: "Too many attempts. Request new OTP" };
  }

  // Verify OTP
  const hashedInput = hashOTP(otp);
  if (hashedInput !== record.otp_hash) {
    // Increment attempts
    await pool.query(
      "UPDATE otp_tokens SET attempts = attempts + 1 WHERE phone = $1",
      [phone]
    );
    return { valid: false, error: "Invalid OTP" };
  }

  // OTP verified - delete it
  await pool.query("DELETE FROM otp_tokens WHERE phone = $1", [phone]);

  return { valid: true };
}

// Send OTP via SMS (placeholder - integrate with MSG91/Twilio)
async function sendOTP(phone, otp) {
  // In development, just log the OTP
  if (process.env.NODE_ENV !== "production") {
    logger.info(`[DEV] OTP for ${phone}: ${otp}`);
    return { sent: true, dev: true };
  }

  // TODO: Integrate with SMS provider (MSG91, Twilio, etc.)
  // Example with MSG91:
  // const response = await fetch('https://api.msg91.com/api/v5/otp', {
  //   method: 'POST',
  //   headers: {
  //     'authkey': process.env.MSG91_AUTH_KEY,
  //     'Content-Type': 'application/json'
  //   },
  //   body: JSON.stringify({
  //     template_id: process.env.MSG91_TEMPLATE_ID,
  //     mobile: `91${phone}`,
  //     otp: otp
  //   })
  // });

  logger.info(`OTP sent to ${phone}`);
  return { sent: true };
}

// Rate limiting check (max 3 OTPs per phone per 10 minutes)
async function checkRateLimit(phone) {
  const tenMinutesAgo = new Date(Date.now() - 10 * 60 * 1000);

  const result = await pool.query(
    `SELECT COUNT(*) FROM otp_logs
     WHERE phone = $1 AND created_at > $2`,
    [phone, tenMinutesAgo]
  );

  return parseInt(result.rows[0].count) < 3;
}

// Log OTP request
async function logOTPRequest(phone) {
  await pool.query(
    `INSERT INTO otp_logs (id, phone, created_at) VALUES ($1, $2, NOW())`,
    [crypto.randomUUID(), phone]
  );
}

module.exports = {
  generateOTP,
  storeOTP,
  verifyOTP,
  sendOTP,
  checkRateLimit,
  logOTPRequest,
};
