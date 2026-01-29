-- Migration 006: Add Search Indexes for Smart Product Search
-- Description: Adds full-text search capabilities and fuzzy matching for product search

-- Enable pg_trgm extension for fuzzy matching (similarity search)
CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- Add category column if it doesn't exist
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'products' AND column_name = 'category'
  ) THEN
    ALTER TABLE products ADD COLUMN category VARCHAR(100);
  END IF;
END $$;

-- Add full-text search index using GIN for fast text search
-- Combines name, description, and category for comprehensive search
CREATE INDEX IF NOT EXISTS products_search_idx ON products
USING GIN (
  to_tsvector('english',
    name || ' ' ||
    COALESCE(description, '') || ' ' ||
    COALESCE(category, '')
  )
);

-- Trigram index already exists, skip if present
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_indexes WHERE indexname = 'products_name_trgm_idx'
  ) THEN
    CREATE INDEX products_name_trgm_idx ON products USING GIN (name gin_trgm_ops);
  END IF;
END $$;

-- Add index on category for category-based filtering
CREATE INDEX IF NOT EXISTS products_category_idx ON products(category);

-- Barcode index already exists, skip

-- Update statistics to optimize query planner
ANALYZE products;

-- Add comments
DO $$
BEGIN
  EXECUTE 'COMMENT ON INDEX products_search_idx IS ''Full-text search index for product names, descriptions, and categories''';
EXCEPTION WHEN undefined_object THEN
  NULL; -- Index doesn't exist yet, skip comment
END $$;
