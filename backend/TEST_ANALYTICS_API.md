# Testing Analytics & Reports API

## Prerequisites

1. Backend server running: `npm run dev` (or `npm start`)
2. PostgreSQL database running with migration 005 applied
3. Admin JWT token (get from login)

## Getting an Admin Token

```bash
# 1. Register/Login as admin (or use existing admin account)
curl -X POST http://localhost:5000/api/auth/send-otp \
  -H "Content-Type: application/json" \
  -d '{"phone": "1234567890"}'

# 2. Verify OTP (replace with actual OTP)
curl -X POST http://localhost:5000/api/auth/verify-otp \
  -H "Content-Type: application/json" \
  -d '{"phone": "1234567890", "otp": "123456"}'

# Save the returned token
export ADMIN_TOKEN="your_jwt_token_here"
```

---

## Analytics Endpoints

### 1. Revenue Chart

**Last 7 Days**
```bash
curl -H "Authorization: Bearer $ADMIN_TOKEN" \
  "http://localhost:5000/api/admin/analytics/revenue?range=7d"
```

**Last 30 Days**
```bash
curl -H "Authorization: Bearer $ADMIN_TOKEN" \
  "http://localhost:5000/api/admin/analytics/revenue?range=30d"
```

**Custom Date Range**
```bash
curl -H "Authorization: Bearer $ADMIN_TOKEN" \
  "http://localhost:5000/api/admin/analytics/revenue?startDate=2026-01-01&endDate=2026-01-28"
```

**Expected Response**:
```json
{
  "success": true,
  "data": [
    {
      "date": "2026-01-21",
      "orders": "5",
      "revenue": "1250.00"
    }
  ],
  "comparison": {
    "current": 8750.50,
    "previous": 7200.00,
    "percentChange": 21.5
  }
}
```

---

### 2. KPI Trends (Today vs Yesterday)

```bash
curl -H "Authorization: Bearer $ADMIN_TOKEN" \
  "http://localhost:5000/api/admin/analytics/kpi-trends"
```

**Expected Response**:
```json
{
  "success": true,
  "revenue": {
    "current": 2500.00,
    "previous": 1800.00,
    "change": 38.9
  },
  "orders": {
    "current": 15,
    "previous": 12,
    "change": 25.0
  },
  "users": {
    "current": 8,
    "previous": 5,
    "change": 60.0
  }
}
```

---

### 3. Sales Summary

**Daily Aggregation**
```bash
curl -H "Authorization: Bearer $ADMIN_TOKEN" \
  "http://localhost:5000/api/admin/analytics/sales/summary?period=daily"
```

**Weekly Aggregation**
```bash
curl -H "Authorization: Bearer $ADMIN_TOKEN" \
  "http://localhost:5000/api/admin/analytics/sales/summary?period=weekly&startDate=2026-01-01&endDate=2026-01-28"
```

**Monthly Aggregation**
```bash
curl -H "Authorization: Bearer $ADMIN_TOKEN" \
  "http://localhost:5000/api/admin/analytics/sales/summary?period=monthly"
```

---

### 4. Peak Hours

```bash
curl -H "Authorization: Bearer $ADMIN_TOKEN" \
  "http://localhost:5000/api/admin/analytics/sales/peak-hours"
```

**Expected Response**:
```json
{
  "success": true,
  "data": [
    { "hour": "9", "order_count": "12", "revenue": "2500.00" },
    { "hour": "10", "order_count": "18", "revenue": "3200.00" },
    { "hour": "14", "order_count": "25", "revenue": "4500.00" }
  ]
}
```

---

### 5. Refund Rate

```bash
curl -H "Authorization: Bearer $ADMIN_TOKEN" \
  "http://localhost:5000/api/admin/analytics/sales/refund-rate"
```

**Expected Response**:
```json
{
  "success": true,
  "paidOrders": 150,
  "refundedOrders": 8,
  "totalRefunded": 1200.50,
  "refundRate": 5.33
}
```

---

### 6. Top Products

**By Revenue (Default)**
```bash
curl -H "Authorization: Bearer $ADMIN_TOKEN" \
  "http://localhost:5000/api/admin/analytics/products/top?metric=revenue&limit=10"
```

**By Quantity Sold**
```bash
curl -H "Authorization: Bearer $ADMIN_TOKEN" \
  "http://localhost:5000/api/admin/analytics/products/top?metric=quantity&limit=10"
```

**Expected Response**:
```json
{
  "success": true,
  "data": [
    {
      "id": "uuid",
      "name": "Product A",
      "category": "Electronics",
      "order_count": "45",
      "units_sold": "120",
      "revenue": "15000.00"
    }
  ]
}
```

---

### 7. Slow Moving Products

```bash
curl -H "Authorization: Bearer $ADMIN_TOKEN" \
  "http://localhost:5000/api/admin/analytics/products/slow-movers"
```

---

### 8. Stock Turnover by Category

```bash
curl -H "Authorization: Bearer $ADMIN_TOKEN" \
  "http://localhost:5000/api/admin/analytics/products/turnover"
```

**Expected Response**:
```json
{
  "success": true,
  "data": [
    {
      "category": "Electronics",
      "avg_stock": "50.5",
      "total_sold": "120",
      "turnover_rate": "2.376"
    }
  ]
}
```

---

### 9. Customer Acquisition

**Last 30 Days (Default)**
```bash
curl -H "Authorization: Bearer $ADMIN_TOKEN" \
  "http://localhost:5000/api/admin/analytics/customers/acquisition?range=30d"
```

**Last 7 Days**
```bash
curl -H "Authorization: Bearer $ADMIN_TOKEN" \
  "http://localhost:5000/api/admin/analytics/customers/acquisition?range=7d"
```

---

### 10. Repeat Purchase Rate

```bash
curl -H "Authorization: Bearer $ADMIN_TOKEN" \
  "http://localhost:5000/api/admin/analytics/customers/repeat-rate"
```

**Expected Response**:
```json
{
  "success": true,
  "totalCustomers": 250,
  "repeatCustomers": 85,
  "repeatRate": 34.00
}
```

---

### 11. Customer Lifetime Value (Top 50)

```bash
curl -H "Authorization: Bearer $ADMIN_TOKEN" \
  "http://localhost:5000/api/admin/analytics/customers/lifetime-value"
```

**Expected Response**:
```json
{
  "success": true,
  "data": [
    {
      "id": "uuid",
      "phone_number": "9876543210",
      "order_count": "25",
      "lifetime_value": "12500.00",
      "last_purchase": "2026-01-27T10:30:00.000Z"
    }
  ]
}
```

---

### 12. Customer Segmentation

```bash
curl -H "Authorization: Bearer $ADMIN_TOKEN" \
  "http://localhost:5000/api/admin/analytics/customers/segmentation"
```

**Expected Response**:
```json
{
  "success": true,
  "data": [
    {
      "segment": "VIP",
      "customer_count": "15",
      "avg_spent": "8500.00"
    },
    {
      "segment": "Loyal",
      "customer_count": "45",
      "avg_spent": "3200.00"
    },
    {
      "segment": "Regular",
      "customer_count": "80",
      "avg_spent": "1500.00"
    },
    {
      "segment": "New",
      "customer_count": "110",
      "avg_spent": "450.00"
    }
  ]
}
```

---

## Export Endpoints

### 1. Export Sales Report

```bash
curl -H "Authorization: Bearer $ADMIN_TOKEN" \
  "http://localhost:5000/api/admin/export/sales?startDate=2026-01-01&endDate=2026-01-28" \
  -o sales_report.csv
```

**CSV Columns**: Order ID, Razorpay Order ID, Customer Phone, Amount, Status, Paid At, Created At

---

### 2. Export Product Performance

```bash
curl -H "Authorization: Bearer $ADMIN_TOKEN" \
  "http://localhost:5000/api/admin/export/products?metric=revenue&limit=50" \
  -o products.csv
```

**CSV Columns**: Product ID, Name, Category, Current Stock, Order Count, Units Sold, Revenue

---

### 3. Export Customer Analytics

```bash
curl -H "Authorization: Bearer $ADMIN_TOKEN" \
  "http://localhost:5000/api/admin/export/customers" \
  -o customers.csv
```

**CSV Columns**: Customer ID, Phone Number, Name, Order Count, Lifetime Value, Segment, First Purchase, Last Purchase

---

## Troubleshooting

### Error: "No paid orders found"
- Ensure you have orders with `status = 'paid'` in the database
- Check that `paid_at` is not null

### Error: "Authorization header missing"
- Make sure you're including the Bearer token: `Authorization: Bearer YOUR_TOKEN`

### Error: "Materialized view does not exist"
- Run migration 005: `psql -U smartexit -d smartexit_db -f migrations/005_analytics_indices.sql`

### Slow Query Performance
- Verify indices are created: `\d orders` in psql
- Check table sizes: `SELECT count(*) FROM orders;`
- Refresh materialized view: `SELECT refresh_daily_revenue_summary();`

---

## Performance Testing

### Test with Large Dataset

```bash
# Generate test data (if needed)
# Run this from backend directory
node generate-test-data.js

# Measure query performance
time curl -H "Authorization: Bearer $ADMIN_TOKEN" \
  "http://localhost:5000/api/admin/analytics/revenue?range=30d"
```

### Expected Response Times
- Revenue chart: < 200ms
- Sales summary: < 300ms
- Product analytics: < 400ms
- Customer analytics: < 500ms
- Exports: < 2000ms

---

## Next Steps

1. Test each endpoint with your admin token
2. Verify CSV exports download correctly
3. Check that all indices are working (`EXPLAIN ANALYZE` in psql)
4. Create Flutter UI screens to visualize this data
5. Set up cron job for materialized view refresh

---

## Support

If you encounter issues:
1. Check backend logs: `npm run dev` output
2. Check database logs: `docker logs smartexit-db`
3. Verify migration status: `SELECT * FROM schema_migrations;`
4. Test with curl first before implementing in Flutter
