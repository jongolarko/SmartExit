const logger = require("../utils/logger");

const errorHandler = (err, req, res, next) => {
  logger.error({
    message: err.message,
    stack: err.stack,
    path: req.path,
    method: req.method,
    user: req.user?.user_id,
  });

  // Joi validation errors
  if (err.isJoi) {
    return res.status(400).json({
      error: "Validation error",
      details: err.details.map((d) => d.message),
    });
  }

  // JWT errors
  if (err.name === "JsonWebTokenError") {
    return res.status(401).json({ error: "Invalid token" });
  }

  if (err.name === "TokenExpiredError") {
    return res.status(401).json({ error: "Token expired" });
  }

  // Database errors
  if (err.code === "23505") {
    return res.status(409).json({ error: "Duplicate entry" });
  }

  if (err.code === "23503") {
    return res.status(400).json({ error: "Referenced record not found" });
  }

  // Default error
  res.status(err.statusCode || 500).json({
    error:
      process.env.NODE_ENV === "production"
        ? "Internal server error"
        : err.message,
  });
};

// 404 handler
const notFoundHandler = (req, res) => {
  res.status(404).json({ error: "Endpoint not found" });
};

module.exports = { errorHandler, notFoundHandler };
