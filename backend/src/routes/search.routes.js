const express = require("express");
const router = express.Router();
const { authenticateToken, optionalAuth } = require("../middleware/auth.middleware");
const {
  searchProducts,
  getCategories,
  getPopularProducts,
  trackSearchConversion,
} = require("../controllers/search.controller");

// Search products (optional auth - better results when logged in)
router.get("/products", optionalAuth, searchProducts);

// Get all categories
router.get("/categories", getCategories);

// Get popular/trending products
router.get("/popular", getPopularProducts);

// Track search-to-cart conversion (requires auth)
router.post("/track-conversion", authenticateToken, trackSearchConversion);

module.exports = router;
