const Joi = require("joi");

// Validation schemas
const schemas = {
  // Auth schemas
  register: Joi.object({
    phone: Joi.string()
      .pattern(/^[6-9]\d{9}$/)
      .required()
      .messages({
        "string.pattern.base": "Invalid Indian phone number",
      }),
    name: Joi.string().min(2).max(100).required(),
  }),

  verifyOtp: Joi.object({
    phone: Joi.string()
      .pattern(/^[6-9]\d{9}$/)
      .required(),
    otp: Joi.string().length(6).required(),
  }),

  login: Joi.object({
    phone: Joi.string()
      .pattern(/^[6-9]\d{9}$/)
      .required(),
    otp: Joi.string().length(6).required(),
  }),

  refreshToken: Joi.object({
    refresh_token: Joi.string().required(),
  }),

  // Cart schemas
  addToCart: Joi.object({
    barcode: Joi.string().min(3).max(50).required(),
    quantity: Joi.number().integer().min(1).max(100).default(1),
  }),

  updateCartItem: Joi.object({
    quantity: Joi.number().integer().min(1).max(100).required(),
  }),

  // Payment schemas
  verifyPayment: Joi.object({
    razorpay_order_id: Joi.string().required(),
    razorpay_payment_id: Joi.string().required(),
    razorpay_signature: Joi.string().required(),
    order_id: Joi.string().uuid().required(),
  }),

  // Exit schemas
  generateExit: Joi.object({
    order_id: Joi.string().uuid().required(),
  }),

  verifyQr: Joi.object({
    exit_token: Joi.string().required(),
  }),

  allowExit: Joi.object({
    exit_token: Joi.string().required(),
    decision: Joi.string().valid("allow", "deny").required(),
  }),
};

// Validation middleware factory
const validate = (schemaName) => {
  return (req, res, next) => {
    const schema = schemas[schemaName];
    if (!schema) {
      return next(new Error(`Schema ${schemaName} not found`));
    }

    const { error, value } = schema.validate(req.body, {
      abortEarly: false,
      stripUnknown: true,
    });

    if (error) {
      return res.status(400).json({
        error: "Validation failed",
        details: error.details.map((d) => d.message),
      });
    }

    req.body = value;
    next();
  };
};

module.exports = { validate, schemas };
