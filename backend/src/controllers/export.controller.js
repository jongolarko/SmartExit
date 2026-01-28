const pool = require('../config/db');
const { generateCSV } = require('../utils/export.utils');
const { error } = require('../utils/response');

// GET /admin/export/sales - Export sales report as CSV
async function exportSalesReport(req, res, next) {
  try {
    const { startDate, endDate } = req.query;

    if (!startDate || !endDate) {
      return error(res, 'startDate and endDate are required', 400);
    }

    const data = await pool.query(
      `SELECT
        o.id, o.razorpay_order_id,
        o.total_amount, o.status,
        o.paid_at, o.created_at,
        u.phone as customer
       FROM orders o
       JOIN users u ON o.user_id = u.id
       WHERE o.paid_at >= $1 AND o.paid_at < $2
       ORDER BY o.paid_at DESC`,
      [startDate, endDate]
    );

    const fields = [
      { label: 'Order ID', value: 'id' },
      { label: 'Razorpay Order ID', value: 'razorpay_order_id' },
      { label: 'Customer Phone', value: 'customer' },
      { label: 'Amount', value: 'total_amount' },
      { label: 'Status', value: 'status' },
      { label: 'Paid At', value: 'paid_at' },
      { label: 'Created At', value: 'created_at' }
    ];

    const csv = generateCSV(data.rows, fields);

    res.setHeader('Content-Type', 'text/csv');
    res.setHeader('Content-Disposition', 'attachment; filename=sales_report.csv');
    res.send(csv);
  } catch (err) {
    next(err);
  }
}

// GET /admin/export/products - Export product performance as CSV
async function exportProductReport(req, res, next) {
  try {
    const { metric = 'revenue', limit = 50 } = req.query;

    const orderBy = metric === 'revenue'
      ? 'SUM(oi.price * oi.quantity)'
      : 'SUM(oi.quantity)';

    const data = await pool.query(
      `SELECT
        p.id, p.name, p.barcode, p.stock,
        COUNT(DISTINCT o.id) as order_count,
        SUM(oi.quantity) as units_sold,
        SUM(oi.price * oi.quantity) as revenue
       FROM products p
       JOIN order_items oi ON p.id = oi.product_id
       JOIN orders o ON oi.order_id = o.id
       WHERE o.status = 'paid'
         AND o.paid_at >= NOW() - INTERVAL '30 days'
       GROUP BY p.id, p.name, p.barcode, p.stock
       ORDER BY ${orderBy} DESC
       LIMIT $1`,
      [limit]
    );

    const fields = [
      { label: 'Product ID', value: 'id' },
      { label: 'Name', value: 'name' },
      { label: 'Barcode', value: 'barcode' },
      { label: 'Current Stock', value: 'stock' },
      { label: 'Order Count', value: 'order_count' },
      { label: 'Units Sold', value: 'units_sold' },
      { label: 'Revenue', value: 'revenue' }
    ];

    const csv = generateCSV(data.rows, fields);

    res.setHeader('Content-Type', 'text/csv');
    res.setHeader('Content-Disposition', 'attachment; filename=product_performance.csv');
    res.send(csv);
  } catch (err) {
    next(err);
  }
}

// GET /admin/export/customers - Export customer analytics as CSV
async function exportCustomerReport(req, res, next) {
  try {
    const data = await pool.query(
      `SELECT
        u.id, u.phone as phone_number, u.name,
        COUNT(o.id) as order_count,
        SUM(o.total_amount) as lifetime_value,
        MAX(o.paid_at) as last_purchase,
        MIN(o.paid_at) as first_purchase,
        CASE
          WHEN COUNT(o.id) >= 10 THEN 'VIP'
          WHEN COUNT(o.id) >= 5 THEN 'Loyal'
          WHEN COUNT(o.id) >= 2 THEN 'Regular'
          ELSE 'New'
        END as segment
       FROM users u
       JOIN orders o ON u.id = o.user_id
       WHERE o.status = 'paid' AND u.role = 'customer'
       GROUP BY u.id, u.phone, u.name
       ORDER BY lifetime_value DESC`
    );

    const fields = [
      { label: 'Customer ID', value: 'id' },
      { label: 'Phone Number', value: 'phone_number' },
      { label: 'Name', value: 'name' },
      { label: 'Order Count', value: 'order_count' },
      { label: 'Lifetime Value', value: 'lifetime_value' },
      { label: 'Segment', value: 'segment' },
      { label: 'First Purchase', value: 'first_purchase' },
      { label: 'Last Purchase', value: 'last_purchase' }
    ];

    const csv = generateCSV(data.rows, fields);

    res.setHeader('Content-Type', 'text/csv');
    res.setHeader('Content-Disposition', 'attachment; filename=customer_analytics.csv');
    res.send(csv);
  } catch (err) {
    next(err);
  }
}

module.exports = {
  exportSalesReport,
  exportProductReport,
  exportCustomerReport
};
