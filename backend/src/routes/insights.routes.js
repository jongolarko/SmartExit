const express = require("express");
const router = express.Router();
const { authenticateToken } = require("../middleware/auth.middleware");
const {
  getSpendingInsights,
  getTimeline,
  getCategoriesInsights,
  getSummary,
  refreshCache,
} = require("../controllers/insights.controller");

// All insights routes require authentication

// Get comprehensive spending insights
router.get("/spending", authenticateToken, getSpendingInsights);

// Get spending timeline for charts
router.get("/timeline", authenticateToken, getTimeline);

// Get category spending trends
router.get("/categories", authenticateToken, getCategoriesInsights);

// Get quick summary stats
router.get("/summary", authenticateToken, getSummary);

// Refresh insights cache
router.post("/refresh", authenticateToken, refreshCache);

module.exports = router;
