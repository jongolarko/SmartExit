-- Migration 007: Add Product Associations Table for Recommendations
-- Description: Creates table to store "frequently bought together" associations

-- Create product_associations table
CREATE TABLE IF NOT EXISTS product_associations (
  product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  related_product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  confidence DECIMAL(5,4) NOT NULL CHECK (confidence >= 0 AND confidence <= 1),
  support INT NOT NULL CHECK (support > 0),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (product_id, related_product_id),
  -- Prevent self-associations
  CHECK (product_id != related_product_id)
);

-- Add indexes for fast lookups
CREATE INDEX IF NOT EXISTS idx_associations_product ON product_associations(product_id);
CREATE INDEX IF NOT EXISTS idx_associations_related ON product_associations(related_product_id);
CREATE INDEX IF NOT EXISTS idx_associations_confidence ON product_associations(confidence DESC);

-- Create reverse associations automatically (if A->B exists, create B->A)
CREATE OR REPLACE FUNCTION create_reverse_association()
RETURNS TRIGGER AS $$
BEGIN
  -- Insert reverse association if it doesn't exist
  INSERT INTO product_associations (product_id, related_product_id, confidence, support)
  VALUES (NEW.related_product_id, NEW.product_id, NEW.confidence, NEW.support)
  ON CONFLICT (product_id, related_product_id) DO UPDATE
  SET confidence = EXCLUDED.confidence,
      support = EXCLUDED.support,
      updated_at = CURRENT_TIMESTAMP;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for automatic reverse associations
DROP TRIGGER IF EXISTS trigger_reverse_association ON product_associations;
CREATE TRIGGER trigger_reverse_association
AFTER INSERT OR UPDATE ON product_associations
FOR EACH ROW
EXECUTE FUNCTION create_reverse_association();

-- Create function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_associations_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = CURRENT_TIMESTAMP;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for updating timestamp
DROP TRIGGER IF EXISTS trigger_update_associations_timestamp ON product_associations;
CREATE TRIGGER trigger_update_associations_timestamp
BEFORE UPDATE ON product_associations
FOR EACH ROW
EXECUTE FUNCTION update_associations_timestamp();

COMMENT ON TABLE product_associations IS 'Stores product association rules for recommendation engine';
COMMENT ON COLUMN product_associations.confidence IS 'Confidence score (0-1): probability that related_product is bought when product is bought';
COMMENT ON COLUMN product_associations.support IS 'Support count: number of times products were bought together';
