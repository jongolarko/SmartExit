const pool = require("../config/db");
const { success, error } = require("../utils/response");

/**
 * Search products using PostgreSQL full-text search
 * GET /api/search/products?q={query}&category={category}&limit={limit}
 */
async function searchProducts(req, res, next) {
  try {
    const { q, category, limit = 20 } = req.query;

    if (!q || q.trim().length === 0) {
      return error(res, "Search query is required", 400);
    }

    const query = q.trim();
    const params = [query];
    let sql = "";

    // Build query with optional category filter
    if (category) {
      sql = `
        SELECT
          p.id,
          p.name,
          p.barcode,
          p.price,
          p.category,
          p.description,
          p.image_url,
          p.stock,
          ts_rank(
            to_tsvector('english', p.name || ' ' || COALESCE(p.description, '') || ' ' || COALESCE(p.category, '')),
            plainto_tsquery('english', $1)
          ) as rank
        FROM products p
        WHERE
          p.category = $2
          AND to_tsvector('english', p.name || ' ' || COALESCE(p.description, '') || ' ' || COALESCE(p.category, ''))
          @@ plainto_tsquery('english', $1)
        ORDER BY rank DESC, p.name
        LIMIT $3
      `;
      params.push(category, limit);
    } else {
      sql = `
        SELECT
          p.id,
          p.name,
          p.barcode,
          p.price,
          p.category,
          p.description,
          p.image_url,
          p.stock,
          ts_rank(
            to_tsvector('english', p.name || ' ' || COALESCE(p.description, '') || ' ' || COALESCE(p.category, '')),
            plainto_tsquery('english', $1)
          ) as rank
        FROM products p
        WHERE
          to_tsvector('english', p.name || ' ' || COALESCE(p.description, '') || ' ' || COALESCE(p.category, ''))
          @@ plainto_tsquery('english', $1)
        ORDER BY rank DESC, p.name
        LIMIT $2
      `;
      params.push(limit);
    }

    const result = await pool.query(sql, params);

    // If no results found, try fuzzy matching (for typos)
    if (result.rows.length === 0) {
      const fuzzyParams = category ? [query, category, limit] : [query, limit];
      const fuzzySql = category
        ? `
          SELECT
            p.id,
            p.name,
            p.barcode,
            p.price,
            p.category,
            p.description,
            p.image_url,
            p.stock,
            similarity(p.name, $1) as rank
          FROM products p
          WHERE
            p.category = $2
            AND similarity(p.name, $1) > 0.3
          ORDER BY similarity(p.name, $1) DESC
          LIMIT $3
        `
        : `
          SELECT
            p.id,
            p.name,
            p.barcode,
            p.price,
            p.category,
            p.description,
            p.image_url,
            p.stock,
            similarity(p.name, $1) as rank
          FROM products p
          WHERE similarity(p.name, $1) > 0.3
          ORDER BY similarity(p.name, $1) DESC
          LIMIT $2
        `;

      const fuzzyResult = await pool.query(fuzzySql, fuzzyParams);

      // Track search usage
      if (req.user) {
        trackFeatureUsage(req.user.user_id, "search", "query", {
          query,
          category,
          results_count: fuzzyResult.rows.length,
          fuzzy_match: true,
        });
      }

      return success(res, {
        products: fuzzyResult.rows,
        query,
        category,
        fuzzy_match: true,
        count: fuzzyResult.rows.length,
      });
    }

    // Track search usage
    if (req.user) {
      trackFeatureUsage(req.user.user_id, "search", "query", {
        query,
        category,
        results_count: result.rows.length,
        fuzzy_match: false,
      });
    }

    return success(res, {
      products: result.rows,
      query,
      category,
      fuzzy_match: false,
      count: result.rows.length,
    });
  } catch (err) {
    next(err);
  }
}

/**
 * Get all product categories
 * GET /api/search/categories
 */
async function getCategories(req, res, next) {
  try {
    const result = await pool.query(`
      SELECT
        category,
        COUNT(*) as product_count
      FROM products
      WHERE category IS NOT NULL
      GROUP BY category
      ORDER BY category
    `);

    return success(res, {
      categories: result.rows,
    });
  } catch (err) {
    next(err);
  }
}

/**
 * Get popular/trending products (most frequently purchased)
 * GET /api/search/popular?limit={limit}
 */
async function getPopularProducts(req, res, next) {
  try {
    const { limit = 10 } = req.query;

    const result = await pool.query(
      `
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
      WHERE o.status = 'paid' OR o.status IS NULL
      GROUP BY p.id
      ORDER BY purchase_count DESC, p.name
      LIMIT $1
    `,
      [limit]
    );

    return success(res, {
      products: result.rows,
    });
  } catch (err) {
    next(err);
  }
}

/**
 * Track search-to-cart conversion
 * POST /api/search/track-conversion
 */
async function trackSearchConversion(req, res, next) {
  try {
    const { query, product_id, category } = req.body;
    const userId = req.user?.user_id;

    if (!userId || !product_id) {
      return error(res, "Missing required fields", 400);
    }

    await trackFeatureUsage(userId, "search", "add_to_cart", {
      query,
      product_id,
      category,
    });

    return success(res, { tracked: true });
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
  searchProducts,
  getCategories,
  getPopularProducts,
  trackSearchConversion,
};
