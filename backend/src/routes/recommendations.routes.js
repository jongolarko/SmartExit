const express = require("express");
const router = express.Router();
const { authenticateToken, optionalAuth } = require("../middleware/auth.middleware");
const auth = require("../middleware/auth.middleware");
const {
  getRecommendationsForProduct,
  getRecommendationsForUser,
  getRecommendationsForCart,
  trackRecommendationClick,
  getStats,
} = require("../controllers/recommendations.controller");

// Get recommendations for a specific product (optional auth)
router.get("/product/:productId", optionalAuth, getRecommendationsForProduct);

// Get personalized recommendations for logged-in user (requires auth)
router.get("/user", authenticateToken, getRecommendationsForUser);

// Get recommendations based on cart contents (optional auth)
router.post("/cart", optionalAuth, getRecommendationsForCart);

// Track recommendation click (requires auth)
router.post("/track-click", authenticateToken, trackRecommendationClick);

// Get recommendation statistics (admin only)
router.get("/stats", auth(["admin"]), getStats);

module.exports = router;
