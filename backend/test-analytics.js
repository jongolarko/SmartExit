#!/usr/bin/env node

/**
 * Test script for Analytics API endpoints
 * Usage: node test-analytics.js
 */

const http = require('http');
const jwt = require('jsonwebtoken');

// Generate admin token
const token = jwt.sign(
  { user_id: 'a27a69fb-434c-4ad1-aec1-ac51bc7e7c88', role: 'admin' },
  process.env.JWT_SECRET || 'smartexit_super_secret_key',
  { expiresIn: '1h' }
);

console.log('🔑 Generated Admin Token:');
console.log(token);
console.log('\n' + '='.repeat(80) + '\n');

// Test endpoints
const endpoints = [
  { name: 'Revenue Chart', path: '/api/admin/analytics/revenue?range=7d' },
  { name: 'KPI Trends', path: '/api/admin/analytics/kpi-trends' },
  { name: 'Sales Summary', path: '/api/admin/analytics/sales/summary?period=daily' },
  { name: 'Peak Hours', path: '/api/admin/analytics/sales/peak-hours' },
  { name: 'Refund Rate', path: '/api/admin/analytics/sales/refund-rate' },
  { name: 'Top Products', path: '/api/admin/analytics/products/top?metric=revenue&limit=5' },
  { name: 'Slow Movers', path: '/api/admin/analytics/products/slow-movers' },
  { name: 'Stock Turnover', path: '/api/admin/analytics/products/turnover' },
  { name: 'Customer Acquisition', path: '/api/admin/analytics/customers/acquisition?range=30d' },
  { name: 'Repeat Rate', path: '/api/admin/analytics/customers/repeat-rate' },
  { name: 'Customer Lifetime Value', path: '/api/admin/analytics/customers/lifetime-value' },
  { name: 'Customer Segmentation', path: '/api/admin/analytics/customers/segmentation' },
];

async function testEndpoint(endpoint, token) {
  return new Promise((resolve, reject) => {
    const options = {
      hostname: 'localhost',
      port: 5000,
      path: endpoint.path,
      method: 'GET',
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json'
      }
    };

    const startTime = Date.now();
    const req = http.request(options, (res) => {
      let data = '';

      res.on('data', (chunk) => {
        data += chunk;
      });

      res.on('end', () => {
        const duration = Date.now() - startTime;
        try {
          const json = JSON.parse(data);
          resolve({
            name: endpoint.name,
            status: res.statusCode,
            duration,
            success: json.success === true,
            data: json
          });
        } catch (e) {
          resolve({
            name: endpoint.name,
            status: res.statusCode,
            duration,
            success: false,
            error: 'Invalid JSON response'
          });
        }
      });
    });

    req.on('error', (e) => {
      reject({
        name: endpoint.name,
        error: e.message
      });
    });

    req.end();
  });
}

async function runTests() {
  console.log('🧪 Testing Analytics Endpoints...\n');

  let passed = 0;
  let failed = 0;

  for (const endpoint of endpoints) {
    try {
      const result = await testEndpoint(endpoint, token);

      const statusIcon = result.success && result.status === 200 ? '✅' : '❌';
      const statusText = result.success ? 'PASS' : 'FAIL';

      console.log(`${statusIcon} ${result.name.padEnd(30)} [${result.status}] ${result.duration}ms`);

      if (result.success && result.status === 200) {
        passed++;
        // Show sample data
        if (result.data && result.data.data) {
          const dataPreview = JSON.stringify(result.data.data).substring(0, 100);
          console.log(`   📊 ${dataPreview}${dataPreview.length >= 100 ? '...' : ''}`);
        }
      } else {
        failed++;
        console.log(`   ⚠️  Error: ${result.error || result.data?.error || 'Unknown error'}`);
      }
      console.log('');
    } catch (error) {
      failed++;
      console.log(`❌ ${endpoint.name.padEnd(30)} ERROR`);
      console.log(`   ⚠️  ${error.error || error.message}`);
      console.log('');
    }
  }

  console.log('='.repeat(80));
  console.log(`\n📊 Test Results: ${passed} passed, ${failed} failed out of ${endpoints.length} total`);

  if (passed === endpoints.length) {
    console.log('\n🎉 All analytics endpoints are working perfectly!\n');
  } else {
    console.log('\n⚠️  Some endpoints need attention.\n');
  }

  // Print curl commands for manual testing
  console.log('\n' + '='.repeat(80));
  console.log('\n📝 Manual Testing Commands:\n');
  console.log(`export TOKEN="${token}"\n`);
  endpoints.forEach(endpoint => {
    console.log(`# ${endpoint.name}`);
    console.log(`curl -H "Authorization: Bearer $TOKEN" "http://localhost:5000${endpoint.path}"\n`);
  });
}

// Run tests
runTests().catch(console.error);
