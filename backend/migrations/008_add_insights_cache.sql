-- Migration 008: Add User Insights Cache Table
-- Description: Creates table to cache user spending insights for performance

-- Create user_insights table
CREATE TABLE IF NOT EXISTS user_insights (
  user_id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  total_spent DECIMAL(10,2) DEFAULT 0 CHECK (total_spent >= 0),
  avg_order_value DECIMAL(10,2) DEFAULT 0 CHECK (avg_order_value >= 0),
  order_count INT DEFAULT 0 CHECK (order_count >= 0),
  favorite_categories JSONB DEFAULT '[]'::jsonb,
  top_products JSONB DEFAULT '[]'::jsonb,
  spending_trend VARCHAR(20) DEFAULT 'stable' CHECK (spending_trend IN ('increasing', 'stable', 'decreasing')),
  trend_percentage DECIMAL(5,2) DEFAULT 0,
  last_order_date TIMESTAMP,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Add indexes for fast lookups
CREATE INDEX IF NOT EXISTS idx_insights_user ON user_insights(user_id);
CREATE INDEX IF NOT EXISTS idx_insights_updated ON user_insights(updated_at DESC);

-- Create function to invalidate insights cache when order is created/updated
CREATE OR REPLACE FUNCTION invalidate_user_insights()
RETURNS TRIGGER AS $$
BEGIN
  -- Delete cached insights for the user to force recalculation
  DELETE FROM user_insights WHERE user_id = NEW.user_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to invalidate cache on new orders
DROP TRIGGER IF EXISTS trigger_invalidate_insights_on_order ON orders;
CREATE TRIGGER trigger_invalidate_insights_on_order
AFTER INSERT OR UPDATE ON orders
FOR EACH ROW
WHEN (NEW.status = 'paid')
EXECUTE FUNCTION invalidate_user_insights();

-- Create function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_insights_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = CURRENT_TIMESTAMP;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for updating timestamp
DROP TRIGGER IF EXISTS trigger_update_insights_timestamp ON user_insights;
CREATE TRIGGER trigger_update_insights_timestamp
BEFORE UPDATE ON user_insights
FOR EACH ROW
EXECUTE FUNCTION update_insights_timestamp();

COMMENT ON TABLE user_insights IS 'Caches user spending analytics for performance optimization';
COMMENT ON COLUMN user_insights.favorite_categories IS 'Array of {category, amount, percentage} objects';
COMMENT ON COLUMN user_insights.top_products IS 'Array of {name, quantity, amount} objects';
COMMENT ON COLUMN user_insights.spending_trend IS 'Trend compared to previous period: increasing/stable/decreasing';
COMMENT ON COLUMN user_insights.trend_percentage IS 'Percentage change in spending (positive or negative)';
