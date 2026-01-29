-- Migration 009: Add Feature Usage Tracking Table
-- Description: Tracks usage of AI features for analytics and optimization

-- Create feature_usage table
CREATE TABLE IF NOT EXISTS feature_usage (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE SET NULL,
  feature VARCHAR(50) NOT NULL,
  action VARCHAR(50),
  metadata JSONB DEFAULT '{}'::jsonb,
  session_id VARCHAR(100),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Add indexes for analytics queries
CREATE INDEX IF NOT EXISTS idx_feature_usage_user ON feature_usage(user_id);
CREATE INDEX IF NOT EXISTS idx_feature_usage_feature ON feature_usage(feature);
CREATE INDEX IF NOT EXISTS idx_feature_usage_created ON feature_usage(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_feature_usage_feature_created ON feature_usage(feature, created_at DESC);

-- Create view for feature usage analytics
CREATE OR REPLACE VIEW feature_usage_stats AS
SELECT
  feature,
  action,
  COUNT(*) as usage_count,
  COUNT(DISTINCT user_id) as unique_users,
  DATE(created_at) as usage_date
FROM feature_usage
GROUP BY feature, action, DATE(created_at);

-- Create function to clean up old feature usage data (older than 90 days)
CREATE OR REPLACE FUNCTION cleanup_old_feature_usage()
RETURNS void AS $$
BEGIN
  DELETE FROM feature_usage
  WHERE created_at < CURRENT_TIMESTAMP - INTERVAL '90 days';
END;
$$ LANGUAGE plpgsql;

COMMENT ON TABLE feature_usage IS 'Tracks AI feature usage for analytics and success metrics';
COMMENT ON COLUMN feature_usage.feature IS 'Feature name: search, recommendation_click, insights_view, etc.';
COMMENT ON COLUMN feature_usage.action IS 'Action taken: query, click, view, add_to_cart, etc.';
COMMENT ON COLUMN feature_usage.metadata IS 'Additional context: {query: "milk", category: "dairy", product_id: "..."}';
COMMENT ON VIEW feature_usage_stats IS 'Aggregated feature usage statistics by date';

-- Example usage tracking values:
-- Feature: 'search', Action: 'query', Metadata: {query: 'milk', results_count: 5}
-- Feature: 'search', Action: 'add_to_cart', Metadata: {query: 'milk', product_id: '...'}
-- Feature: 'recommendation', Action: 'view', Metadata: {source: 'cart', count: 3}
-- Feature: 'recommendation', Action: 'click', Metadata: {product_id: '...', source: 'cart'}
-- Feature: 'insights', Action: 'view', Metadata: {period: 'month'}
