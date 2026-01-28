-- Phase 4: Analytics & Reports - Performance Indices and Materialized Views
-- Migration 005: Analytics Indices

-- Performance indices for analytics queries
CREATE INDEX IF NOT EXISTS idx_orders_status_paid_date
  ON orders(status, paid_at DESC) WHERE status = 'paid';

CREATE INDEX IF NOT EXISTS idx_orders_created_date
  ON orders(created_at DESC);

CREATE INDEX IF NOT EXISTS idx_order_items_product
  ON order_items(product_id);

CREATE INDEX IF NOT EXISTS idx_users_created_date
  ON users(created_at DESC);

CREATE INDEX IF NOT EXISTS idx_users_role
  ON users(role) WHERE role = 'customer';

-- Materialized view for daily revenue summary
CREATE MATERIALIZED VIEW IF NOT EXISTS daily_revenue_summary AS
SELECT
  DATE(paid_at) as date,
  COUNT(*) as order_count,
  SUM(total_amount) as revenue,
  AVG(total_amount) as avg_order_value
FROM orders
WHERE status = 'paid'
GROUP BY DATE(paid_at)
ORDER BY date DESC;

CREATE INDEX IF NOT EXISTS idx_daily_revenue_date
  ON daily_revenue_summary(date);

-- Refresh function for materialized view
CREATE OR REPLACE FUNCTION refresh_daily_revenue_summary()
RETURNS void AS $$
BEGIN
  REFRESH MATERIALIZED VIEW CONCURRENTLY daily_revenue_summary;
END;
$$ LANGUAGE plpgsql;

-- Grant permissions
GRANT SELECT ON daily_revenue_summary TO smartexit;
GRANT EXECUTE ON FUNCTION refresh_daily_revenue_summary() TO smartexit;
