const express = require("express");
const router = express.Router();
const auth = require("../middleware/auth.middleware");
const notificationService = require("../services/notification.service");
const { success, error } = require("../utils/response");
const Joi = require("joi");

// Validation schemas
const registerSchema = Joi.object({
  token: Joi.string().required(),
  platform: Joi.string().valid("android", "ios", "web").required(),
});

const unregisterSchema = Joi.object({
  token: Joi.string().required(),
});

// All routes require authentication (all roles)
router.use(auth());

// POST /notifications/register - Register device token
router.post("/register", async (req, res, next) => {
  try {
    const { error: validationError, value } = registerSchema.validate(req.body);
    if (validationError) {
      return error(res, validationError.details[0].message, 400);
    }

    const userId = req.user.user_id;
    const { token, platform } = value;

    const registered = await notificationService.registerToken(
      userId,
      token,
      platform
    );

    if (registered) {
      return success(res, { message: "Device token registered" });
    }

    return error(res, "Failed to register device token", 500);
  } catch (err) {
    next(err);
  }
});

// POST /notifications/unregister - Unregister device token
router.post("/unregister", async (req, res, next) => {
  try {
    const { error: validationError, value } = unregisterSchema.validate(
      req.body
    );
    if (validationError) {
      return error(res, validationError.details[0].message, 400);
    }

    const userId = req.user.user_id;
    const { token } = value;

    await notificationService.unregisterToken(userId, token);

    return success(res, { message: "Device token unregistered" });
  } catch (err) {
    next(err);
  }
});

module.exports = router;
