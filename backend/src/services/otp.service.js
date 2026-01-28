const crypto = require("crypto");
const pool = require("../config/db");
const logger = require("../utils/logger");

// Lazy-loaded Twilio client
let twilioClient = null;

function getTwilioClient() {
  if (!twilioClient && process.env.TWILIO_ACCOUNT_SID && process.env.TWILIO_AUTH_TOKEN) {
    const twilio = require("twilio");
    twilioClient = twilio(
      process.env.TWILIO_ACCOUNT_SID,
      process.env.TWILIO_AUTH_TOKEN
    );
  }
  return twilioClient;
}

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

// Send OTP via SMS using Twilio
async function sendOTP(phone, otp) {
  // In development, just log the OTP
  if (process.env.NODE_ENV !== "production") {
    logger.info(`[DEV] OTP for ${phone}: ${otp}`);
    return { sent: true, dev: true };
  }

  // Get Twilio client
  const client = getTwilioClient();

  if (!client) {
    logger.warn("Twilio not configured, falling back to console logging");
    logger.info(`[FALLBACK] OTP for ${phone}: ${otp}`);
    return { sent: true, fallback: true };
  }

  try {
    // Format phone number with country code (default +91 for India)
    const formattedPhone = phone.startsWith("+") ? phone : `+91${phone}`;

    await client.messages.create({
      body: `Your SmartExit verification code is: ${otp}. Valid for 5 minutes.`,
      from: process.env.TWILIO_PHONE_NUMBER,
      to: formattedPhone,
    });

    logger.info(`OTP sent successfully to ${formattedPhone}`);
    return { sent: true };
  } catch (err) {
    logger.error(`Failed to send OTP via Twilio: ${err.message}`);
    throw new Error("Failed to send OTP. Please try again.");
  }
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
