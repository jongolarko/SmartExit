-- Inventory Management Migration
-- Run this migration to add inventory management features

-- Add reorder management fields to products
ALTER TABLE products ADD COLUMN IF NOT EXISTS reorder_level INT DEFAULT 10;
ALTER TABLE products ADD COLUMN IF NOT EXISTS max_stock INT DEFAULT 1000;

-- Stock audit log table for tracking all stock changes
CREATE TABLE IF NOT EXISTS stock_audit_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    product_id UUID REFERENCES products(id) ON DELETE CASCADE,
    change_type VARCHAR(20) NOT NULL CHECK (change_type IN ('sale', 'adjustment', 'receipt', 'damage', 'return', 'correction')),
    quantity_change INT NOT NULL,     -- positive for additions, negative for reductions
    quantity_before INT,
    quantity_after INT,
    reason TEXT,
    performed_by UUID REFERENCES users(id),
    created_at TIMESTAMP DEFAULT NOW()
);

-- Indexes for efficient queries
CREATE INDEX IF NOT EXISTS idx_stock_audit_product ON stock_audit_logs(product_id);
CREATE INDEX IF NOT EXISTS idx_stock_audit_date ON stock_audit_logs(created_at);
CREATE INDEX IF NOT EXISTS idx_stock_audit_type ON stock_audit_logs(change_type);
CREATE INDEX IF NOT EXISTS idx_products_reorder ON products(reorder_level) WHERE stock IS NOT NULL;

-- Update existing products with default reorder levels
UPDATE products SET reorder_level = 10 WHERE reorder_level IS NULL;
UPDATE products SET max_stock = 1000 WHERE max_stock IS NULL;
