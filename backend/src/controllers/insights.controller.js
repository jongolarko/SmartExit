const pool = require("../config/db");
const { success, error } = require("../utils/response");
const {
  getUserInsights,
  getSpendingTimeline,
  getCategoryTrends,
  updateUserInsightsCache,
} = require("../services/insights.service");

/**
 * Get comprehensive spending insights for logged-in user
 * GET /api/insights/spending?period=month
 */
async function getSpendingInsights(req, res, next) {
  try {
    const userId = req.user.user_id;
    const { period = 'month' } = req.query;

    // Validate period
    if (!['week', 'month'].includes(period)) {
      return error(res, "Invalid period. Use 'week' or 'month'", 400);
    }

    const insights = await getUserInsights(userId, period);

    // Track feature usage
    await trackFeatureUsage(userId, 'insights', 'view', {
      period,
      total_spent: insights.summary.total_spent,
      order_count: insights.summary.order_count,
    });

    return success(res, {
      period,
      insights,
    });
  } catch (err) {
    next(err);
  }
}

/**
 * Get spending timeline for charts
 * GET /api/insights/timeline?period=month
 */
async function getTimeline(req, res, next) {
  try {
    const userId = req.user.user_id;
    const { period = 'month' } = req.query;

    // Validate period
    if (!['week', 'month'].includes(period)) {
      return error(res, "Invalid period. Use 'week' or 'month'", 400);
    }

    const timeline = await getSpendingTimeline(userId, period);

    return success(res, {
      period,
      timeline,
    });
  } catch (err) {
    next(err);
  }
}

/**
 * Get category spending trends over time
 * GET /api/insights/categories?period=month
 */
async function getCategoriesInsights(req, res, next) {
  try {
    const userId = req.user.user_id;
    const { period = 'month' } = req.query;

    // Validate period
    if (!['week', 'month'].includes(period)) {
      return error(res, "Invalid period. Use 'week' or 'month'", 400);
    }

    const trends = await getCategoryTrends(userId, period);

    return success(res, {
      period,
      trends,
    });
  } catch (err) {
    next(err);
  }
}

/**
 * Get quick summary stats
 * GET /api/insights/summary
 */
async function getSummary(req, res, next) {
  try {
    const userId = req.user.user_id;

    // Get cached insights if available
    const cacheQuery = `
      SELECT
        total_spent,
        avg_order_value,
        order_count,
        favorite_categories,
        spending_trend,
        updated_at
      FROM user_insights
      WHERE user_id = $1
    `;

    const cacheResult = await pool.query(cacheQuery, [userId]);

    if (cacheResult.rows.length > 0) {
      const cached = cacheResult.rows[0];
      const cacheAge = Date.now() - new Date(cached.updated_at).getTime();
      const cacheMaxAge = 24 * 60 * 60 * 1000; // 24 hours

      // Return cached data if less than 24 hours old
      if (cacheAge < cacheMaxAge) {
        return success(res, {
          ...cached,
          cached: true,
          cache_age_hours: Math.floor(cacheAge / (60 * 60 * 1000)),
        });
      }
    }

    // Generate fresh insights
    const insights = await getUserInsights(userId, 'month');

    // Update cache asynchronously (don't wait for it)
    updateUserInsightsCache(userId).catch(err =>
      console.error("Failed to update insights cache:", err)
    );

    return success(res, {
      total_spent: insights.summary.total_spent,
      avg_order_value: insights.summary.avg_order_value,
      order_count: insights.summary.order_count,
      favorite_categories: insights.categories.slice(0, 3),
      spending_trend: insights.trend.trend,
      cached: false,
    });
  } catch (err) {
    next(err);
  }
}

/**
 * Refresh insights cache manually
 * POST /api/insights/refresh
 */
async function refreshCache(req, res, next) {
  try {
    const userId = req.user.user_id;

    await updateUserInsightsCache(userId);

    return success(res, {
      message: "Insights cache updated successfully",
    });
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
  getSpendingInsights,
  getTimeline,
  getCategoriesInsights,
  getSummary,
  refreshCache,
};
