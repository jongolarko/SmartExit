require("dotenv").config();

const { server } = require("./src/app");
const logger = require("./src/utils/logger");

const PORT = process.env.PORT || 5000;

server.listen(PORT, () => {
  logger.info(`SmartExit API server running on port ${PORT}`);
  logger.info(`Environment: ${process.env.NODE_ENV || "development"}`);
  logger.info(`Socket.io enabled for realtime updates`);
});

// Graceful shutdown
process.on("SIGTERM", () => {
  logger.info("SIGTERM received, shutting down gracefully");
  server.close(() => {
    logger.info("Server closed");
    process.exit(0);
  });
});

process.on("SIGINT", () => {
  logger.info("SIGINT received, shutting down gracefully");
  server.close(() => {
    logger.info("Server closed");
    process.exit(0);
  });
});
