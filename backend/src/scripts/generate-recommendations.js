#!/usr/bin/env node

/**
 * Generate Product Recommendations Script
 *
 * This script generates product associations based on order history
 * Run it manually or schedule it as a daily cron job
 *
 * Usage:
 *   node src/scripts/generate-recommendations.js
 *
 * Cron schedule (daily at 2 AM):
 *   0 2 * * * cd /path/to/backend && node src/scripts/generate-recommendations.js
 */

require("dotenv").config();
const { generateProductAssociations } = require("../services/recommendations.service");

async function main() {
  console.log("===============================================");
  console.log("Product Recommendation Generation");
  console.log("===============================================");
  console.log(`Started at: ${new Date().toISOString()}`);
  console.log("");

  try {
    const result = await generateProductAssociations();

    if (result.success) {
      console.log("✓ Associations generated successfully!");
      console.log("");
      console.log("Statistics:");
      console.log(`  - Total associations: ${result.associations_generated}`);
      console.log(`  - Average confidence: ${parseFloat(result.stats.avg_confidence).toFixed(4)}`);
      console.log(`  - Max confidence: ${parseFloat(result.stats.max_confidence).toFixed(4)}`);
      console.log(`  - Average support: ${parseFloat(result.stats.avg_support).toFixed(2)}`);
      console.log(`  - Max support: ${result.stats.max_support}`);
      console.log("");
      console.log(`Completed at: ${new Date().toISOString()}`);
      process.exit(0);
    } else {
      console.error("✗ Failed to generate associations");
      console.error(`Error: ${result.error}`);
      process.exit(1);
    }
  } catch (err) {
    console.error("✗ Script error:", err.message);
    console.error(err.stack);
    process.exit(1);
  }
}

// Run the script
main();
