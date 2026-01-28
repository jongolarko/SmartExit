-- Admin Management Migration
-- Adds admin activity logs and refund tracking

-- Admin Activity Logs for audit trail
CREATE TABLE IF NOT EXISTS admin_activity_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    admin_id UUID NOT NULL REFERENCES users(id),
    action VARCHAR(50) NOT NULL,
    entity_type VARCHAR(30) NOT NULL,
    entity_id UUID,
    details JSONB,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Add refund tracking to orders
ALTER TABLE orders ADD COLUMN IF NOT EXISTS refund_id VARCHAR(100);
ALTER TABLE orders ADD COLUMN IF NOT EXISTS refund_amount DECIMAL(10, 2);
ALTER TABLE orders ADD COLUMN IF NOT EXISTS refunded_at TIMESTAMP;
ALTER TABLE orders ADD COLUMN IF NOT EXISTS refund_reason TEXT;

-- Indexes for admin activity logs
CREATE INDEX IF NOT EXISTS idx_admin_activity_admin ON admin_activity_logs(admin_id);
CREATE INDEX IF NOT EXISTS idx_admin_activity_entity ON admin_activity_logs(entity_type, entity_id);
CREATE INDEX IF NOT EXISTS idx_admin_activity_date ON admin_activity_logs(created_at);

-- Index for refund lookups
CREATE INDEX IF NOT EXISTS idx_orders_refund_id ON orders(refund_id) WHERE refund_id IS NOT NULL;
