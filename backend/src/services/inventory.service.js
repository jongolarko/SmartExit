const pool = require("../config/db");
const logger = require("../utils/logger");
const notificationService = require("./notification.service");

/**
 * Adjust stock for a product with audit logging
 * @param {string} productId - Product UUID
 * @param {number} quantity - Quantity to adjust (positive or negative)
 * @param {string} changeType - Type: 'sale', 'adjustment', 'receipt', 'damage', 'return', 'correction'
 * @param {string} reason - Reason for the adjustment
 * @param {string} userId - User performing the adjustment
 * @returns {Promise<{success: boolean, product?: object, error?: string}>}
 */
async function adjustStock(productId, quantity, changeType, reason, userId) {
  const client = await pool.connect();

  try {
    await client.query("BEGIN");

    // Get current product stock
    const productRes = await client.query(
      "SELECT id, name, stock, reorder_level FROM products WHERE id = $1 FOR UPDATE",
      [productId]
    );

    if (productRes.rows.length === 0) {
      await client.query("ROLLBACK");
      return { success: false, error: "Product not found" };
    }

    const product = productRes.rows[0];
    const currentStock = product.stock || 0;
    const newStock = Math.max(0, currentStock + quantity);

    // Update product stock
    await client.query(
      "UPDATE products SET stock = $1, updated_at = NOW() WHERE id = $2",
      [newStock, productId]
    );

    // Create audit log entry
    await client.query(
      `INSERT INTO stock_audit_logs
       (product_id, change_type, quantity_change, quantity_before, quantity_after, reason, performed_by)
       VALUES ($1, $2, $3, $4, $5, $6, $7)`,
      [productId, changeType, quantity, currentStock, newStock, reason, userId]
    );

    await client.query("COMMIT");

    logger.info(
      `Stock adjusted for product ${productId}: ${currentStock} -> ${newStock} (${changeType})`
    );

    // Check if stock fell below reorder level and trigger alert
    if (newStock < product.reorder_level && currentStock >= product.reorder_level) {
      await triggerLowStockAlert(product.id, product.name, newStock, product.reorder_level);
    }

    return {
      success: true,
      product: {
        id: productId,
        name: product.name,
        stock: newStock,
        previousStock: currentStock,
        reorderLevel: product.reorder_level,
      },
    };
  } catch (err) {
    await client.query("ROLLBACK");
    logger.error(`Failed to adjust stock: ${err.message}`);
    return { success: false, error: err.message };
  } finally {
    client.release();
  }
}

/**
 * Get products below reorder level
 * @returns {Promise<Array>} List of low stock products
 */
async function getLowStockProducts() {
  try {
    const result = await pool.query(
      `SELECT p.id, p.barcode, p.name, p.stock, p.reorder_level, p.max_stock, p.price,
              (SELECT COUNT(*) FROM stock_audit_logs sal WHERE sal.product_id = p.id AND sal.created_at > NOW() - INTERVAL '7 days') as recent_movements
       FROM products p
       WHERE p.stock IS NOT NULL AND p.stock < p.reorder_level
       ORDER BY p.stock ASC`
    );
    return result.rows;
  } catch (err) {
    logger.error(`Failed to get low stock products: ${err.message}`);
    return [];
  }
}

/**
 * Get stock movement report for a date range
 * @param {Date} startDate - Start date
 * @param {Date} endDate - End date
 * @param {string} productId - Optional product ID filter
 * @returns {Promise<Array>} Stock movement records
 */
async function getStockReport(startDate, endDate, productId = null) {
  try {
    let query = `
      SELECT sal.id, sal.change_type, sal.quantity_change, sal.quantity_before, sal.quantity_after,
             sal.reason, sal.created_at,
             p.id as product_id, p.name as product_name, p.barcode,
             u.name as performed_by_name
      FROM stock_audit_logs sal
      JOIN products p ON sal.product_id = p.id
      LEFT JOIN users u ON sal.performed_by = u.id
      WHERE sal.created_at >= $1 AND sal.created_at <= $2
    `;

    const params = [startDate, endDate];

    if (productId) {
      query += " AND sal.product_id = $3";
      params.push(productId);
    }

    query += " ORDER BY sal.created_at DESC";

    const result = await pool.query(query, params);
    return result.rows;
  } catch (err) {
    logger.error(`Failed to get stock report: ${err.message}`);
    return [];
  }
}

/**
 * Get stock summary statistics
 * @returns {Promise<object>} Summary statistics
 */
async function getStockSummary() {
  try {
    const result = await pool.query(`
      SELECT
        COUNT(*) FILTER (WHERE stock IS NOT NULL AND stock < reorder_level) as low_stock_count,
        COUNT(*) FILTER (WHERE stock IS NOT NULL AND stock = 0) as out_of_stock_count,
        COUNT(*) FILTER (WHERE stock IS NOT NULL AND stock >= reorder_level) as healthy_stock_count,
        COUNT(*) as total_products,
        COALESCE(SUM(stock * price), 0) as total_inventory_value
      FROM products
    `);

    return result.rows[0];
  } catch (err) {
    logger.error(`Failed to get stock summary: ${err.message}`);
    return {
      low_stock_count: 0,
      out_of_stock_count: 0,
      healthy_stock_count: 0,
      total_products: 0,
      total_inventory_value: 0,
    };
  }
}

/**
 * Trigger low stock alert notification to admins
 * @param {string} productId - Product ID
 * @param {string} productName - Product name
 * @param {number} currentStock - Current stock level
 * @param {number} reorderLevel - Reorder level threshold
 */
async function triggerLowStockAlert(productId, productName, currentStock, reorderLevel) {
  try {
    // Get all admin users
    const adminsRes = await pool.query(
      "SELECT id FROM users WHERE role = 'admin'"
    );

    // Send notification to each admin
    for (const admin of adminsRes.rows) {
      await notificationService.sendToUser(
        admin.id,
        {
          title: "Low Stock Alert",
          body: `${productName} is running low (${currentStock} left, reorder at ${reorderLevel})`,
        },
        {
          type: "low_stock_alert",
          product_id: productId,
          current_stock: currentStock.toString(),
          reorder_level: reorderLevel.toString(),
        }
      );
    }

    logger.info(`Low stock alert sent for product ${productId}`);
  } catch (err) {
    logger.error(`Failed to send low stock alert: ${err.message}`);
  }
}

/**
 * Check all products and trigger alerts for those below reorder level
 * Used for scheduled/batch processing
 */
async function checkAndAlertLowStock() {
  try {
    const lowStockProducts = await getLowStockProducts();

    for (const product of lowStockProducts) {
      await triggerLowStockAlert(
        product.id,
        product.name,
        product.stock,
        product.reorder_level
      );
    }

    logger.info(`Checked ${lowStockProducts.length} low stock products`);
    return lowStockProducts.length;
  } catch (err) {
    logger.error(`Failed to check low stock: ${err.message}`);
    return 0;
  }
}

/**
 * Get audit history for a specific product
 * @param {string} productId - Product UUID
 * @param {number} limit - Number of records to return
 * @returns {Promise<Array>} Audit log entries
 */
async function getProductAuditHistory(productId, limit = 50) {
  try {
    const result = await pool.query(
      `SELECT sal.*, u.name as performed_by_name
       FROM stock_audit_logs sal
       LEFT JOIN users u ON sal.performed_by = u.id
       WHERE sal.product_id = $1
       ORDER BY sal.created_at DESC
       LIMIT $2`,
      [productId, limit]
    );
    return result.rows;
  } catch (err) {
    logger.error(`Failed to get product audit history: ${err.message}`);
    return [];
  }
}

module.exports = {
  adjustStock,
  getLowStockProducts,
  getStockReport,
  getStockSummary,
  triggerLowStockAlert,
  checkAndAlertLowStock,
  getProductAuditHistory,
};
