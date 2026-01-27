-- SmartExit Database Schema
-- Run this migration to set up the database

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Users table
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    phone VARCHAR(15) UNIQUE NOT NULL,
    name VARCHAR(100) NOT NULL,
    role VARCHAR(20) DEFAULT 'customer' CHECK (role IN ('customer', 'security', 'admin')),
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Pending registrations (for OTP verification)
CREATE TABLE IF NOT EXISTS pending_registrations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    phone VARCHAR(15) UNIQUE NOT NULL,
    name VARCHAR(100) NOT NULL,
    created_at TIMESTAMP DEFAULT NOW()
);

-- OTP tokens
CREATE TABLE IF NOT EXISTS otp_tokens (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    phone VARCHAR(15) NOT NULL,
    otp_hash VARCHAR(64) NOT NULL,
    attempts INT DEFAULT 0,
    expires_at TIMESTAMP NOT NULL,
    created_at TIMESTAMP DEFAULT NOW()
);

-- OTP request logs (for rate limiting)
CREATE TABLE IF NOT EXISTS otp_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    phone VARCHAR(15) NOT NULL,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Refresh tokens
CREATE TABLE IF NOT EXISTS refresh_tokens (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token TEXT NOT NULL,
    expires_at TIMESTAMP NOT NULL,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Products table
CREATE TABLE IF NOT EXISTS products (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    barcode VARCHAR(50) UNIQUE NOT NULL,
    name VARCHAR(200) NOT NULL,
    description TEXT,
    price DECIMAL(10, 2) NOT NULL,
    stock INT,
    image_url TEXT,
    hsn_code VARCHAR(8),
    gst_rate DECIMAL(5, 2) DEFAULT 18.00,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Carts table
CREATE TABLE IF NOT EXISTS carts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'completed', 'abandoned')),
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Cart items table
CREATE TABLE IF NOT EXISTS cart_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    cart_id UUID NOT NULL REFERENCES carts(id) ON DELETE CASCADE,
    product_id UUID NOT NULL REFERENCES products(id),
    quantity INT NOT NULL DEFAULT 1,
    price DECIMAL(10, 2) NOT NULL,
    created_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(cart_id, product_id)
);

-- Orders table
CREATE TABLE IF NOT EXISTS orders (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id),
    razorpay_order_id VARCHAR(100),
    razorpay_payment_id VARCHAR(100),
    total_amount DECIMAL(10, 2) NOT NULL,
    cgst DECIMAL(10, 2),
    sgst DECIMAL(10, 2),
    igst DECIMAL(10, 2),
    invoice_number VARCHAR(20) UNIQUE,
    status VARCHAR(20) DEFAULT 'created' CHECK (status IN ('created', 'paid', 'failed', 'refunded', 'cancelled')),
    created_at TIMESTAMP DEFAULT NOW(),
    paid_at TIMESTAMP,
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Order items table
CREATE TABLE IF NOT EXISTS order_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    product_id UUID NOT NULL REFERENCES products(id),
    quantity INT NOT NULL,
    price DECIMAL(10, 2) NOT NULL,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Gate access table (exit tokens)
CREATE TABLE IF NOT EXISTS gate_access (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id),
    order_id UUID NOT NULL REFERENCES orders(id),
    exit_token VARCHAR(50) UNIQUE NOT NULL,
    expires_at TIMESTAMP NOT NULL,
    verified BOOLEAN DEFAULT FALSE,
    allowed BOOLEAN,
    verified_by UUID REFERENCES users(id),
    verified_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_users_phone ON users(phone);
CREATE INDEX IF NOT EXISTS idx_products_barcode ON products(barcode);
CREATE INDEX IF NOT EXISTS idx_carts_user_status ON carts(user_id, status);
CREATE INDEX IF NOT EXISTS idx_orders_user ON orders(user_id);
CREATE INDEX IF NOT EXISTS idx_orders_status ON orders(status);
CREATE INDEX IF NOT EXISTS idx_gate_access_token ON gate_access(exit_token);
CREATE INDEX IF NOT EXISTS idx_gate_access_order ON gate_access(order_id);
CREATE INDEX IF NOT EXISTS idx_otp_tokens_phone ON otp_tokens(phone);
CREATE INDEX IF NOT EXISTS idx_refresh_tokens_user ON refresh_tokens(user_id);

-- Seed data for testing
INSERT INTO users (id, phone, name, role) VALUES
    ('a27a69fb-434c-4ad1-aec1-ac51bc7e7c88', '9999999999', 'Admin User', 'admin'),
    ('b27a69fb-434c-4ad1-aec1-ac51bc7e7c89', '9999999998', 'Security Guard', 'security'),
    ('c27a69fb-434c-4ad1-aec1-ac51bc7e7c90', '9999999997', 'Test Customer', 'customer')
ON CONFLICT (phone) DO NOTHING;

-- Sample products
INSERT INTO products (id, barcode, name, price, stock, description) VALUES
    (uuid_generate_v4(), 'PROD001', 'Coca Cola 500ml', 40.00, 100, 'Refreshing carbonated drink'),
    (uuid_generate_v4(), 'PROD002', 'Lays Classic Chips', 20.00, 200, 'Crispy potato chips'),
    (uuid_generate_v4(), 'PROD003', 'Dairy Milk Silk', 80.00, 150, 'Premium chocolate bar'),
    (uuid_generate_v4(), 'PROD004', 'Maggi Noodles', 14.00, 300, 'Instant noodles 2-min'),
    (uuid_generate_v4(), 'PROD005', 'Amul Butter 100g', 55.00, 50, 'Fresh butter')
ON CONFLICT (barcode) DO NOTHING;

-- Cleanup old OTP tokens (run periodically)
-- DELETE FROM otp_tokens WHERE expires_at < NOW();
-- DELETE FROM otp_logs WHERE created_at < NOW() - INTERVAL '1 day';
