-- Seed data for recommendations testing
-- Creates sample orders with multiple items to demonstrate associations

-- Order 1: Cola + Chips (common combo)
INSERT INTO orders (id, user_id, total_amount, razorpay_payment_id, status, created_at, paid_at)
VALUES (
  '11111111-1111-1111-1111-111111111111',
  'c27a69fb-434c-4ad1-aec1-ac51bc7e7c90',
  80.00,
  'pay_demo1',
  'paid',
  NOW() - INTERVAL '5 days',
  NOW() - INTERVAL '5 days'
);

INSERT INTO order_items (order_id, product_id, quantity, price)
SELECT
  '11111111-1111-1111-1111-111111111111',
  id,
  1,
  price
FROM products WHERE barcode = 'PROD001'
UNION ALL
SELECT
  '11111111-1111-1111-1111-111111111111',
  id,
  1,
  price
FROM products WHERE barcode = 'PROD004';

-- Order 2: Cola + Chips again (strengthen association)
INSERT INTO orders (id, user_id, total_amount, razorpay_payment_id, status, created_at, paid_at)
VALUES (
  '11111111-2222-2222-2222-222222222223',
  'c27a69fb-434c-4ad1-aec1-ac51bc7e7c90',
  80.00,
  'pay_demo2',
  'paid',
  NOW() - INTERVAL '4 days',
  NOW() - INTERVAL '4 days'
);

INSERT INTO order_items (order_id, product_id, quantity, price)
SELECT
  '11111111-2222-2222-2222-222222222223',
  id,
  1,
  price
FROM products WHERE barcode = 'PROD001'
UNION ALL
SELECT
  '11111111-2222-2222-2222-222222222223',
  id,
  1,
  price
FROM products WHERE barcode = 'PROD004';

-- Order 3: Dairy Milk + Butter (dairy combo)
INSERT INTO orders (id, user_id, total_amount, razorpay_payment_id, status, created_at, paid_at)
VALUES (
  '11111111-3333-3333-3333-333333333333',
  'c27a69fb-434c-4ad1-aec1-ac51bc7e7c90',
  135.00,
  'pay_demo3',
  'paid',
  NOW() - INTERVAL '3 days',
  NOW() - INTERVAL '3 days'
);

INSERT INTO order_items (order_id, product_id, quantity, price)
SELECT
  '11111111-3333-3333-3333-333333333333',
  id,
  1,
  price
FROM products WHERE barcode = 'PROD003'
UNION ALL
SELECT
  '11111111-3333-3333-3333-333333333333',
  id,
  1,
  price
FROM products WHERE barcode = 'PROD005';

-- Order 4: Cola + Chips + Biscuit (3-item combo)
INSERT INTO orders (id, user_id, total_amount, razorpay_payment_id, status, created_at, paid_at)
VALUES (
  '11111111-4444-4444-4444-444444444444',
  'c27a69fb-434c-4ad1-aec1-ac51bc7e7c90',
  100.00,
  'pay_demo4',
  'paid',
  NOW() - INTERVAL '2 days',
  NOW() - INTERVAL '2 days'
);

INSERT INTO order_items (order_id, product_id, quantity, price)
SELECT
  '11111111-4444-4444-4444-444444444444',
  id,
  1,
  price
FROM products WHERE barcode = 'PROD001'
UNION ALL
SELECT
  '11111111-4444-4444-4444-444444444444',
  id,
  1,
  price
FROM products WHERE barcode = 'PROD004'
UNION ALL
SELECT
  '11111111-4444-4444-4444-444444444444',
  id,
  1,
  price
FROM products WHERE barcode = 'PROD002';

-- Order 5: Dairy Milk + Butter again (strengthen dairy association)
INSERT INTO orders (id, user_id, total_amount, razorpay_payment_id, status, created_at, paid_at)
VALUES (
  '11111111-5555-5555-5555-555555555555',
  'c27a69fb-434c-4ad1-aec1-ac51bc7e7c90',
  135.00,
  'pay_demo5',
  'paid',
  NOW() - INTERVAL '1 day',
  NOW() - INTERVAL '1 day'
);

INSERT INTO order_items (order_id, product_id, quantity, price)
SELECT
  '11111111-5555-5555-5555-555555555555',
  id,
  1,
  price
FROM products WHERE barcode = 'PROD003'
UNION ALL
SELECT
  '11111111-5555-5555-5555-555555555555',
  id,
  1,
  price
FROM products WHERE barcode = 'PROD005';
