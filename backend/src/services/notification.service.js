const pool = require("../config/db");
const { getMessaging, isFirebaseConfigured } = require("../config/firebase");
const logger = require("../utils/logger");

/**
 * Register a device token for a user
 */
async function registerToken(userId, token, platform) {
  try {
    // Upsert the token (update if exists, insert if not)
    await pool.query(
      `INSERT INTO device_tokens (user_id, token, platform, updated_at)
       VALUES ($1, $2, $3, NOW())
       ON CONFLICT (user_id, token)
       DO UPDATE SET platform = $3, updated_at = NOW()`,
      [userId, token, platform]
    );

    logger.info(`Device token registered for user ${userId} (${platform})`);
    return true;
  } catch (err) {
    logger.error(`Failed to register device token: ${err.message}`);
    return false;
  }
}

/**
 * Unregister a device token
 */
async function unregisterToken(userId, token) {
  try {
    await pool.query(
      "DELETE FROM device_tokens WHERE user_id = $1 AND token = $2",
      [userId, token]
    );

    logger.info(`Device token unregistered for user ${userId}`);
    return true;
  } catch (err) {
    logger.error(`Failed to unregister device token: ${err.message}`);
    return false;
  }
}

/**
 * Get all device tokens for a user
 */
async function getUserTokens(userId) {
  try {
    const result = await pool.query(
      "SELECT token, platform FROM device_tokens WHERE user_id = $1",
      [userId]
    );
    return result.rows;
  } catch (err) {
    logger.error(`Failed to get user tokens: ${err.message}`);
    return [];
  }
}

/**
 * Send push notification to a user
 */
async function sendToUser(userId, notification, data = {}) {
  if (!isFirebaseConfigured()) {
    logger.warn("Firebase not configured, skipping push notification");
    return { success: false, reason: "firebase_not_configured" };
  }

  const tokens = await getUserTokens(userId);

  if (tokens.length === 0) {
    logger.info(`No device tokens found for user ${userId}`);
    return { success: false, reason: "no_tokens" };
  }

  const messaging = getMessaging();
  if (!messaging) {
    return { success: false, reason: "messaging_unavailable" };
  }

  const tokenStrings = tokens.map((t) => t.token);
  const invalidTokens = [];

  try {
    const response = await messaging.sendEachForMulticast({
      tokens: tokenStrings,
      notification: {
        title: notification.title,
        body: notification.body,
      },
      data: {
        ...data,
        // Ensure all values are strings for FCM
        ...Object.fromEntries(
          Object.entries(data).map(([k, v]) => [k, String(v)])
        ),
      },
      android: {
        priority: "high",
        notification: {
          channelId: "smartexit_notifications",
          icon: "ic_notification",
        },
      },
      apns: {
        payload: {
          aps: {
            sound: "default",
            badge: 1,
          },
        },
      },
    });

    // Check for failed tokens and remove them
    response.responses.forEach((resp, idx) => {
      if (!resp.success) {
        const error = resp.error;
        if (
          error?.code === "messaging/invalid-registration-token" ||
          error?.code === "messaging/registration-token-not-registered"
        ) {
          invalidTokens.push(tokenStrings[idx]);
        }
      }
    });

    // Clean up invalid tokens
    if (invalidTokens.length > 0) {
      await Promise.all(
        invalidTokens.map((token) =>
          pool.query("DELETE FROM device_tokens WHERE token = $1", [token])
        )
      );
      logger.info(`Removed ${invalidTokens.length} invalid device tokens`);
    }

    const successCount = response.successCount;
    logger.info(
      `Push notification sent to user ${userId}: ${successCount}/${tokenStrings.length} succeeded`
    );

    return {
      success: successCount > 0,
      successCount,
      failureCount: response.failureCount,
    };
  } catch (err) {
    logger.error(`Failed to send push notification: ${err.message}`);
    return { success: false, reason: "send_failed", error: err.message };
  }
}

/**
 * Send payment success notification
 */
async function sendPaymentSuccessNotification(userId, orderId, amount) {
  return sendToUser(
    userId,
    {
      title: "Payment Successful",
      body: `Your payment of \u20B9${amount.toFixed(2)} has been confirmed. Show your exit QR to leave.`,
    },
    {
      type: "payment_success",
      order_id: orderId,
      amount: amount.toString(),
    }
  );
}

/**
 * Send exit approved notification
 */
async function sendExitApprovedNotification(userId, exitToken) {
  return sendToUser(
    userId,
    {
      title: "Exit Approved",
      body: "Your exit has been approved. Please proceed through the gate.",
    },
    {
      type: "exit_approved",
      exit_token: exitToken,
    }
  );
}

/**
 * Send exit denied notification
 */
async function sendExitDeniedNotification(userId, exitToken, reason) {
  return sendToUser(
    userId,
    {
      title: "Exit Denied",
      body: reason || "Please contact store staff for assistance.",
    },
    {
      type: "exit_denied",
      exit_token: exitToken,
    }
  );
}

module.exports = {
  registerToken,
  unregisterToken,
  getUserTokens,
  sendToUser,
  sendPaymentSuccessNotification,
  sendExitApprovedNotification,
  sendExitDeniedNotification,
};
