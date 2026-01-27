require("dotenv").config();

const express = require("express");
const http = require("http");
const cors = require("cors");
const helmet = require("helmet");
const compression = require("compression");
const rateLimit = require("express-rate-limit");

const routes = require("./routes");
const { initializeSocket } = require("./config/socket");
const { errorHandler, notFoundHandler } = require("./middleware/error.middleware");
const logger = require("./utils/logger");

const app = express();
const server = http.createServer(app);

// Initialize Socket.io
initializeSocket(server);

// Security middleware
app.use(helmet());
app.use(cors({
  origin: process.env.CORS_ORIGIN || "*",
  credentials: true,
}));

// Rate limiting
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // Limit each IP to 100 requests per windowMs
  message: { error: "Too many requests, please try again later" },
  standardHeaders: true,
  legacyHeaders: false,
});
app.use(limiter);

// Stricter rate limit for auth routes
const authLimiter = rateLimit({
  windowMs: 10 * 60 * 1000, // 10 minutes
  max: 10, // 10 requests per 10 minutes
  message: { error: "Too many auth attempts, please try again later" },
});
app.use("/api/auth", authLimiter);

// Body parsing
app.use(express.json({ limit: "10mb" }));
app.use(express.urlencoded({ extended: true, limit: "10mb" }));

// Compression
app.use(compression());

// Request logging in development
if (process.env.NODE_ENV !== "production") {
  app.use((req, res, next) => {
    logger.info(`${req.method} ${req.path}`);
    next();
  });
}

// Health check
app.get("/", (req, res) => {
  res.json({
    status: "ok",
    service: "SmartExit API",
    version: "2.0.0",
    timestamp: new Date().toISOString(),
  });
});

app.get("/health", (req, res) => {
  res.json({ status: "healthy" });
});

// API routes
app.use("/api", routes);

// Serve static files (for test pages)
app.use("/public", express.static("Public"));

// 404 handler
app.use(notFoundHandler);

// Error handler
app.use(errorHandler);

module.exports = { app, server };
