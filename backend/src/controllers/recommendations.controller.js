const pool = require("../config/db");
const { success, error } = require("../utils/response");
const {
  getProductRecommendations,
  getUserRecommendations,
  getCartRecommendations,
  getPopularProducts,
  getRecommendationStats,
} = require("../services/recommendations.service");

/**
 * Get recommendations for a specific product
 * GET /api/recommendations/product/:productId?limit=5
 */
async function getRecommendationsForProduct(req, res, next) {
  try {
    const { productId } = req.params;
    const { limit = 5 } = req.query;

    // Verify product exists
    const productCheck = await pool.query(
      "SELECT id FROM products WHERE id = $1",
      [productId]
    );

    if (productCheck.rows.length === 0) {
      return error(res, "Product not found", 404);
    }

    const recommendations = await getProductRecommendations(
      productId,
      parseInt(limit)
    );

    // Track feature usage
    if (req.user) {
      await trackFeatureUsage(req.user.user_id, "recommendation", "view", {
        source: "product",
        product_id: productId,
        count: recommendations.length,
      });
    }

    return success(res, {
      product_id: productId,
      recommendations,
      count: recommendations.length,
    });
  } catch (err) {
    next(err);
  }
}

/**
 * Get personalized recommendations for logged-in user
 * GET /api/recommendations/user?limit=10
 */
async function getRecommendationsForUser(req, res, next) {
  try {
    const userId = req.user.user_id;
    const { limit = 10 } = req.query;

    const recommendations = await getUserRecommendations(
      userId,
      parseInt(limit)
    );

    // If no personalized recommendations, fall back to popular products
    if (recommendations.length === 0) {
      const popular = await getPopularProducts(parseInt(limit));

      // Track feature usage
      await trackFeatureUsage(userId, "recommendation", "view", {
        source: "user",
        fallback: "popular",
        count: popular.length,
      });

      return success(res, {
        recommendations: popular,
        count: popular.length,
        fallback: true,
        message: "No personalized recommendations yet. Showing popular products.",
      });
    }

    // Track feature usage
    await trackFeatureUsage(userId, "recommendation", "view", {
      source: "user",
      count: recommendations.length,
    });

    return success(res, {
      recommendations,
      count: recommendations.length,
      fallback: false,
    });
  } catch (err) {
    next(err);
  }
}

/**
 * Get recommendations based on cart contents
 * POST /api/recommendations/cart
 * Body: { product_ids: ["uuid1", "uuid2", ...] }
 */
async function getRecommendationsForCart(req, res, next) {
  try {
    const { product_ids } = req.body;
    const { limit = 5 } = req.query;

    if (!product_ids || !Array.isArray(product_ids) || product_ids.length === 0) {
      return error(res, "product_ids array is required", 400);
    }

    const recommendations = await getCartRecommendations(
      product_ids,
      parseInt(limit)
    );

    // Track feature usage
    if (req.user) {
      await trackFeatureUsage(req.user.user_id, "recommendation", "view", {
        source: "cart",
        cart_size: product_ids.length,
        count: recommendations.length,
      });
    }

    return success(res, {
      cart_products: product_ids,
      recommendations,
      count: recommendations.length,
    });
  } catch (err) {
    next(err);
  }
}

/**
 * Track when user clicks on a recommendation
 * POST /api/recommendations/track-click
 * Body: { product_id: "uuid", recommended_product_id: "uuid", source: "cart|user|product" }
 */
async function trackRecommendationClick(req, res, next) {
  try {
    const { product_id, recommended_product_id, source } = req.body;
    const userId = req.user?.user_id;

    if (!recommended_product_id || !source) {
      return error(res, "recommended_product_id and source are required", 400);
    }

    // Track feature usage
    if (userId) {
      await trackFeatureUsage(userId, "recommendation", "click", {
        source,
        product_id,
        recommended_product_id,
      });
    }

    return success(res, { tracked: true });
  } catch (err) {
    next(err);
  }
}

/**
 * Get recommendation system statistics (admin only)
 * GET /api/recommendations/stats
 */
async function getStats(req, res, next) {
  try {
    const stats = await getRecommendationStats();
    return success(res, stats);
  } catch (err) {
    next(err);
  }
}

/**
 * Helper function to track feature usage
 */
async function trackFeatureUsage(userId, feature, action, metadata = {}) {
  try {
    await pool.query(
      `INSERT INTO feature_usage (user_id, feature, action, metadata)
       VALUES ($1, $2, $3, $4)`,
      [userId, feature, action, JSON.stringify(metadata)]
    );
  } catch (err) {
    console.error("Error tracking feature usage:", err);
    // Don't throw - tracking failures shouldn't break the main flow
  }
}

module.exports = {
  getRecommendationsForProduct,
  getRecommendationsForUser,
  getRecommendationsForCart,
  trackRecommendationClick,
  getStats,
};
