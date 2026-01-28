const { Parser } = require('json2csv');

/**
 * Generate CSV from JSON data
 * @param {Array} data - Array of objects to convert to CSV
 * @param {Array} fields - Array of field names/configurations
 * @returns {string} CSV string
 */
function generateCSV(data, fields) {
  try {
    const json2csvParser = new Parser({ fields });
    return json2csvParser.parse(data);
  } catch (error) {
    throw new Error(`CSV generation failed: ${error.message}`);
  }
}

module.exports = { generateCSV };
