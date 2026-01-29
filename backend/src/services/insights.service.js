const pool = require("../config/db");

/**
 * Insights Service - SQL-based Analytics
 * Provides spending insights and analytics using PostgreSQL aggregations
 */

/**
 * Get comprehensive spending insights for a user
 * @param {string} userId - User ID
 * @param {string} period - 'week' or 'month'
 * @returns {Object} Comprehensive spending insights
 */
async function getUserInsights(userId, period = 'month') {
  try {
    const insights = {};

    // Calculate interval for SQL queries
    const interval = period === 'week' ? '1 week' : '1 month';
    const previousInterval = period === 'week' ? '2 week' : '2 month';

    // 1. Total spending summary
    const summaryQuery = `
      SELECT
        COALESCE(SUM(total_amount), 0) as total_spent,
        COUNT(*) as order_count,
        COALESCE(AVG(total_amount), 0) as avg_order_value,
        MAX(total_amount) as max_order_value,
        MIN(total_amount) as min_order_value
      FROM orders
      WHERE user_id = $1
        AND status = 'paid'
        AND created_at >= NOW() - INTERVAL '${interval}'
    `;

    const summaryResult = await pool.query(summaryQuery, [userId]);
    insights.summary = summaryResult.rows[0];

    // 2. Category breakdown
    const categoryQuery = `
      SELECT
        COALESCE(p.category, 'Uncategorized') as category,
        SUM(oi.quantity * oi.price) as category_total,
        COUNT(DISTINCT oi.order_id) as order_count,
        SUM(oi.quantity) as item_count,
        ROUND((SUM(oi.quantity * oi.price) / NULLIF(
          (SELECT SUM(total_amount) FROM orders
           WHERE user_id = $1 AND status = 'paid'
           AND created_at >= NOW() - INTERVAL '${interval}'), 0
        ) * 100)::numeric, 2) as percentage
      FROM order_items oi
      JOIN products p ON oi.product_id = p.id
      JOIN orders o ON oi.order_id = o.id
      WHERE o.user_id = $1
        AND o.status = 'paid'
        AND o.created_at >= NOW() - INTERVAL '${interval}'
      GROUP BY p.category
      ORDER BY category_total DESC
    `;

    const categoryResult = await pool.query(categoryQuery, [userId]);
    insights.categories = categoryResult.rows;

    // 3. Spending trend (compare to previous period)
    const trendQuery = `
      WITH current_period AS (
        SELECT COALESCE(SUM(total_amount), 0) as total
        FROM orders
        WHERE user_id = $1 AND status = 'paid'
          AND created_at >= NOW() - INTERVAL '${interval}'
      ),
      previous_period AS (
        SELECT COALESCE(SUM(total_amount), 0) as total
        FROM orders
        WHERE user_id = $1 AND status = 'paid'
          AND created_at >= NOW() - INTERVAL '${previousInterval}'
          AND created_at < NOW() - INTERVAL '${interval}'
      )
      SELECT
        current_period.total as current_total,
        previous_period.total as previous_total,
        CASE
          WHEN previous_period.total = 0 THEN NULL
          ELSE ROUND(((current_period.total - previous_period.total) /
                NULLIF(previous_period.total, 0) * 100)::numeric, 2)
        END as change_percent,
        CASE
          WHEN current_period.total > previous_period.total THEN 'increasing'
          WHEN current_period.total < previous_period.total THEN 'decreasing'
          ELSE 'stable'
        END as trend
      FROM current_period, previous_period
    `;

    const trendResult = await pool.query(trendQuery, [userId]);
    insights.trend = trendResult.rows[0];

    // 4. Top products
    const topProductsQuery = `
      SELECT
        p.id,
        p.name,
        p.barcode,
        p.category,
        SUM(oi.quantity) as total_quantity,
        SUM(oi.quantity * oi.price) as total_spent,
        COUNT(DISTINCT oi.order_id) as order_count
      FROM order_items oi
      JOIN products p ON oi.product_id = p.id
      JOIN orders o ON oi.order_id = o.id
      WHERE o.user_id = $1 AND o.status = 'paid'
        AND o.created_at >= NOW() - INTERVAL '${interval}'
      GROUP BY p.id, p.name, p.barcode, p.category
      ORDER BY total_spent DESC
      LIMIT 5
    `;

    const topProductsResult = await pool.query(topProductsQuery, [userId]);
    insights.top_products = topProductsResult.rows;

    // 5. Shopping frequency
    const frequencyQuery = `
      SELECT
        COUNT(DISTINCT DATE(created_at)) as shopping_days,
        ROUND(COUNT(*)::numeric /
          NULLIF(COUNT(DISTINCT DATE(created_at)), 0), 2) as avg_orders_per_day
      FROM orders
      WHERE user_id = $1 AND status = 'paid'
        AND created_at >= NOW() - INTERVAL '${interval}'
    `;

    const frequencyResult = await pool.query(frequencyQuery, [userId]);
    insights.frequency = frequencyResult.rows[0];

    // 6. Weekly spending pattern
    const weeklyPatternQuery = `
      SELECT
        TO_CHAR(created_at, 'Day') as day_name,
        EXTRACT(DOW FROM created_at) as day_number,
        COUNT(*) as order_count,
        COALESCE(SUM(total_amount), 0) as total_spent
      FROM orders
      WHERE user_id = $1 AND status = 'paid'
        AND created_at >= NOW() - INTERVAL '${interval}'
      GROUP BY day_name, day_number
      ORDER BY day_number
    `;

    const weeklyPatternResult = await pool.query(weeklyPatternQuery, [userId]);
    insights.weekly_pattern = weeklyPatternResult.rows;

    // 7. Time-based spending distribution
    const timeDistributionQuery = `
      WITH time_data AS (
        SELECT
          CASE
            WHEN EXTRACT(HOUR FROM created_at) BETWEEN 6 AND 11 THEN 'Morning'
            WHEN EXTRACT(HOUR FROM created_at) BETWEEN 12 AND 17 THEN 'Afternoon'
            WHEN EXTRACT(HOUR FROM created_at) BETWEEN 18 AND 22 THEN 'Evening'
            ELSE 'Night'
          END as time_of_day,
          COUNT(*) as order_count,
          COALESCE(SUM(total_amount), 0) as total_spent
        FROM orders
        WHERE user_id = $1 AND status = 'paid'
          AND created_at >= NOW() - INTERVAL '${interval}'
        GROUP BY
          CASE
            WHEN EXTRACT(HOUR FROM created_at) BETWEEN 6 AND 11 THEN 'Morning'
            WHEN EXTRACT(HOUR FROM created_at) BETWEEN 12 AND 17 THEN 'Afternoon'
            WHEN EXTRACT(HOUR FROM created_at) BETWEEN 18 AND 22 THEN 'Evening'
            ELSE 'Night'
          END
      )
      SELECT * FROM time_data
      ORDER BY
        CASE time_of_day
          WHEN 'Morning' THEN 1
          WHEN 'Afternoon' THEN 2
          WHEN 'Evening' THEN 3
          WHEN 'Night' THEN 4
        END
    `;

    const timeDistributionResult = await pool.query(timeDistributionQuery, [userId]);
    insights.time_distribution = timeDistributionResult.rows;

    return insights;
  } catch (err) {
    console.error("Error getting user insights:", err);
    throw err;
  }
}

/**
 * Get spending timeline (daily spending for charts)
 * @param {string} userId - User ID
 * @param {string} period - 'week' or 'month'
 * @returns {Array} Daily spending data
 */
async function getSpendingTimeline(userId, period = 'month') {
  try {
    const days = period === 'week' ? 7 : 30;
    const interval = period === 'week' ? '1 week' : '1 month';

    const query = `
      WITH date_series AS (
        SELECT generate_series(
          CURRENT_DATE - INTERVAL '${interval}',
          CURRENT_DATE,
          '1 day'::interval
        )::date as date
      )
      SELECT
        ds.date,
        TO_CHAR(ds.date, 'Dy') as day_name,
        COALESCE(SUM(o.total_amount), 0) as amount,
        COUNT(o.id) as order_count
      FROM date_series ds
      LEFT JOIN orders o ON DATE(o.created_at) = ds.date
        AND o.user_id = $1
        AND o.status = 'paid'
      GROUP BY ds.date
      ORDER BY ds.date
    `;

    const result = await pool.query(query, [userId]);
    return result.rows;
  } catch (err) {
    console.error("Error getting spending timeline:", err);
    throw err;
  }
}

/**
 * Get category spending over time
 * @param {string} userId - User ID
 * @param {string} period - 'week' or 'month'
 * @returns {Array} Category spending timeline
 */
async function getCategoryTrends(userId, period = 'month') {
  try {
    const interval = period === 'week' ? '1 week' : '1 month';

    const query = `
      SELECT
        COALESCE(p.category, 'Uncategorized') as category,
        DATE(o.created_at) as date,
        SUM(oi.quantity * oi.price) as amount
      FROM order_items oi
      JOIN products p ON oi.product_id = p.id
      JOIN orders o ON oi.order_id = o.id
      WHERE o.user_id = $1
        AND o.status = 'paid'
        AND o.created_at >= NOW() - INTERVAL '${interval}'
      GROUP BY p.category, DATE(o.created_at)
      ORDER BY date, category
    `;

    const result = await pool.query(query, [userId]);
    return result.rows;
  } catch (err) {
    console.error("Error getting category trends:", err);
    throw err;
  }
}

/**
 * Update or create user insights cache
 * This can be called periodically to pre-compute insights
 */
async function updateUserInsightsCache(userId) {
  try {
    // Get month insights
    const insights = await getUserInsights(userId, 'month');

    const query = `
      INSERT INTO user_insights (
        user_id,
        total_spent,
        avg_order_value,
        order_count,
        favorite_categories,
        spending_trend,
        updated_at
      )
      VALUES ($1, $2, $3, $4, $5, $6, CURRENT_TIMESTAMP)
      ON CONFLICT (user_id) DO UPDATE SET
        total_spent = EXCLUDED.total_spent,
        avg_order_value = EXCLUDED.avg_order_value,
        order_count = EXCLUDED.order_count,
        favorite_categories = EXCLUDED.favorite_categories,
        spending_trend = EXCLUDED.spending_trend,
        updated_at = CURRENT_TIMESTAMP
    `;

    const favoriteCategories = insights.categories
      .slice(0, 3)
      .map(cat => ({ name: cat.category, amount: parseFloat(cat.category_total) }));

    await pool.query(query, [
      userId,
      parseFloat(insights.summary.total_spent),
      parseFloat(insights.summary.avg_order_value),
      parseInt(insights.summary.order_count),
      JSON.stringify(favoriteCategories),
      insights.trend.trend,
    ]);

    return { success: true };
  } catch (err) {
    console.error("Error updating insights cache:", err);
    throw err;
  }
}

module.exports = {
  getUserInsights,
  getSpendingTimeline,
  getCategoryTrends,
  updateUserInsightsCache,
};
