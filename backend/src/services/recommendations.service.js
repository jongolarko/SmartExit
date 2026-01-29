const pool = require("../config/db");

/**
 * Recommendations Service - Market Basket Analysis
 * Uses association rules (Apriori algorithm) to find product associations
 */

/**
 * Generate product associations from order history
 * Run this as a daily cron job to update recommendations
 *
 * Algorithm:
 * 1. Find all product pairs that appear together in orders
 * 2. Calculate support (how many times they appear together)
 * 3. Calculate confidence (probability B is bought when A is bought)
 * 4. Store associations with confidence >= threshold
 */
async function generateProductAssociations() {
  const minSupport = 3; // Minimum times products must appear together
  const minConfidence = 0.1; // Minimum 10% confidence

  console.log("Starting product association generation...");

  try {
    // Disable trigger temporarily to avoid recursion
    await pool.query("ALTER TABLE product_associations DISABLE TRIGGER trigger_reverse_association");

    // Clear old associations
    await pool.query("DELETE FROM product_associations");

    // Find product pairs that appear together in orders
    const associationsQuery = `
      WITH order_pairs AS (
        SELECT
          oi1.product_id as product_a,
          oi2.product_id as product_b,
          COUNT(DISTINCT oi1.order_id) as frequency
        FROM order_items oi1
        JOIN order_items oi2 ON oi1.order_id = oi2.order_id
        JOIN orders o ON oi1.order_id = o.id
        WHERE oi1.product_id < oi2.product_id  -- Avoid duplicates and self-pairs
          AND o.status = 'paid'  -- Only count completed orders
        GROUP BY oi1.product_id, oi2.product_id
        HAVING COUNT(DISTINCT oi1.order_id) >= $1  -- Minimum support
      ),
      product_order_counts AS (
        SELECT
          oi.product_id,
          COUNT(DISTINCT oi.order_id) as order_count
        FROM order_items oi
        JOIN orders o ON oi.order_id = o.id
        WHERE o.status = 'paid'
        GROUP BY oi.product_id
      )
      INSERT INTO product_associations (product_id, related_product_id, confidence, support)
      SELECT
        op.product_a as product_id,
        op.product_b as related_product_id,
        (op.frequency::decimal / poc.order_count) as confidence,
        op.frequency as support
      FROM order_pairs op
      JOIN product_order_counts poc ON op.product_a = poc.product_id
      WHERE (op.frequency::decimal / poc.order_count) >= $2  -- Minimum confidence
      ORDER BY confidence DESC
    `;

    const result = await pool.query(associationsQuery, [minSupport, minConfidence]);

    // Re-enable trigger
    await pool.query("ALTER TABLE product_associations ENABLE TRIGGER trigger_reverse_association");

    console.log(`Generated ${result.rowCount} product associations`);

    // Get statistics
    const stats = await pool.query(`
      SELECT
        COUNT(*) as total_associations,
        AVG(confidence) as avg_confidence,
        MAX(confidence) as max_confidence,
        AVG(support) as avg_support,
        MAX(support) as max_support
      FROM product_associations
    `);

    return {
      success: true,
      associations_generated: result.rowCount,
      stats: stats.rows[0],
    };
  } catch (err) {
    console.error("Error generating associations:", err);
    return {
      success: false,
      error: err.message,
    };
  }
}

/**
 * Get product recommendations based on a single product
 * Returns products frequently bought with the given product
 */
async function getProductRecommendations(productId, limit = 5) {
  try {
    const query = `
      SELECT
        p.id,
        p.name,
        p.barcode,
        p.price,
        p.category,
        p.description,
        p.image_url,
        p.stock,
        pa.confidence,
        pa.support
      FROM product_associations pa
      JOIN products p ON pa.related_product_id = p.id
      WHERE pa.product_id = $1
      ORDER BY pa.confidence DESC, pa.support DESC
      LIMIT $2
    `;

    const result = await pool.query(query, [productId, limit]);
    return result.rows;
  } catch (err) {
    console.error("Error getting product recommendations:", err);
    throw err;
  }
}

/**
 * Get recommendations based on user's order history
 * Returns products user hasn't bought but are associated with their purchases
 */
async function getUserRecommendations(userId, limit = 10) {
  try {
    const query = `
      WITH user_products AS (
        -- Get all products user has ordered
        SELECT DISTINCT oi.product_id
        FROM order_items oi
        JOIN orders o ON oi.order_id = o.id
        WHERE o.user_id = $1 AND o.status = 'paid'
      ),
      recommended_products AS (
        -- Find products associated with user's purchases
        SELECT
          pa.related_product_id as product_id,
          SUM(pa.confidence * pa.support) as score
        FROM product_associations pa
        WHERE pa.product_id IN (SELECT product_id FROM user_products)
          AND pa.related_product_id NOT IN (SELECT product_id FROM user_products)
        GROUP BY pa.related_product_id
        ORDER BY score DESC
        LIMIT $2
      )
      SELECT
        p.id,
        p.name,
        p.barcode,
        p.price,
        p.category,
        p.description,
        p.image_url,
        p.stock,
        rp.score
      FROM recommended_products rp
      JOIN products p ON rp.product_id = p.id
      ORDER BY rp.score DESC
    `;

    const result = await pool.query(query, [userId, limit]);
    return result.rows;
  } catch (err) {
    console.error("Error getting user recommendations:", err);
    throw err;
  }
}

/**
 * Get recommendations based on current cart contents
 * Returns products frequently bought with items in the cart
 */
async function getCartRecommendations(productIds, limit = 5) {
  try {
    if (!productIds || productIds.length === 0) {
      return [];
    }

    const query = `
      WITH recommended_products AS (
        SELECT
          pa.related_product_id as product_id,
          SUM(pa.confidence * pa.support) as score
        FROM product_associations pa
        WHERE pa.product_id = ANY($1::uuid[])
          AND pa.related_product_id != ALL($1::uuid[])
        GROUP BY pa.related_product_id
        ORDER BY score DESC
        LIMIT $2
      )
      SELECT
        p.id,
        p.name,
        p.barcode,
        p.price,
        p.category,
        p.description,
        p.image_url,
        p.stock,
        rp.score
      FROM recommended_products rp
      JOIN products p ON rp.product_id = p.id
      ORDER BY rp.score DESC
    `;

    const result = await pool.query(query, [productIds, limit]);
    return result.rows;
  } catch (err) {
    console.error("Error getting cart recommendations:", err);
    throw err;
  }
}

/**
 * Get popular products (most frequently purchased)
 * Fallback when no personalized recommendations available
 */
async function getPopularProducts(limit = 10) {
  try {
    const query = `
      SELECT
        p.id,
        p.name,
        p.barcode,
        p.price,
        p.category,
        p.description,
        p.image_url,
        p.stock,
        COUNT(oi.id) as purchase_count
      FROM products p
      LEFT JOIN order_items oi ON p.id = oi.product_id
      LEFT JOIN orders o ON oi.order_id = o.id
      WHERE o.status = 'paid' OR o.id IS NULL
      GROUP BY p.id
      ORDER BY purchase_count DESC, p.name
      LIMIT $1
    `;

    const result = await pool.query(query, [limit]);
    return result.rows;
  } catch (err) {
    console.error("Error getting popular products:", err);
    throw err;
  }
}

/**
 * Get recommendation statistics
 * Used for monitoring the recommendation system
 */
async function getRecommendationStats() {
  try {
    const stats = await pool.query(`
      SELECT
        COUNT(*) as total_associations,
        COUNT(DISTINCT product_id) as products_with_recommendations,
        AVG(confidence) as avg_confidence,
        AVG(support) as avg_support,
        MAX(updated_at) as last_updated
      FROM product_associations
    `);

    const topAssociations = await pool.query(`
      SELECT
        p1.name as product_name,
        p2.name as recommended_product_name,
        pa.confidence,
        pa.support
      FROM product_associations pa
      JOIN products p1 ON pa.product_id = p1.id
      JOIN products p2 ON pa.related_product_id = p2.id
      ORDER BY pa.confidence DESC, pa.support DESC
      LIMIT 10
    `);

    return {
      summary: stats.rows[0],
      top_associations: topAssociations.rows,
    };
  } catch (err) {
    console.error("Error getting recommendation stats:", err);
    throw err;
  }
}

module.exports = {
  generateProductAssociations,
  getProductRecommendations,
  getUserRecommendations,
  getCartRecommendations,
  getPopularProducts,
  getRecommendationStats,
};
