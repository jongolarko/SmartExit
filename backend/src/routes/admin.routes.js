const express = require("express");
const router = express.Router();
const adminController = require("../controllers/admin.controller");
const exportController = require("../controllers/export.controller");
const auth = require("../middleware/auth.middleware");

// All admin routes require admin role
router.use(auth(["admin"]));

// Dashboard
router.get("/dashboard", adminController.getDashboard);

// Orders - IMPORTANT: More specific routes must come before generic :id routes
router.get("/orders", adminController.getOrders);
router.post("/orders/:orderId/refund", adminController.refundOrder);
router.put("/orders/:orderId/cancel", adminController.cancelOrder);
router.get("/orders/:id", adminController.getOrderDetails);

// Users - IMPORTANT: More specific routes must come before generic :id routes
router.get("/users", adminController.getUsers);
router.get("/users/:id/orders", adminController.getUserOrders);
router.put("/users/:id/role", adminController.updateUserRole);
router.get("/users/:id", adminController.getUserDetails);

// Security logs
router.get("/security-logs", adminController.getSecurityLogs);

// Products - IMPORTANT: More specific routes must come before generic :id routes
router.get("/products", adminController.getProducts);
router.post("/products", adminController.createProduct);
router.post("/products/:id/stock", adminController.adjustStock);
router.get("/products/:id/history", adminController.getProductHistory);
router.put("/products/:id", adminController.updateProduct);
router.delete("/products/:id", adminController.deleteProduct);

// Inventory
router.get("/inventory/low-stock", adminController.getLowStockProducts);
router.get("/inventory/report", adminController.getInventoryReport);

// Analytics - Phase 4
router.get("/analytics/revenue", adminController.getRevenueChart);
router.get("/analytics/kpi-trends", adminController.getKpiTrends);
router.get("/analytics/sales/summary", adminController.getSalesSummary);
router.get("/analytics/sales/peak-hours", adminController.getPeakHours);
router.get("/analytics/sales/refund-rate", adminController.getRefundRate);
router.get("/analytics/products/top", adminController.getTopProducts);
router.get("/analytics/products/slow-movers", adminController.getSlowMovers);
router.get("/analytics/products/turnover", adminController.getStockTurnover);
router.get("/analytics/customers/acquisition", adminController.getCustomerAcquisition);
router.get("/analytics/customers/repeat-rate", adminController.getRepeatRate);
router.get("/analytics/customers/lifetime-value", adminController.getCustomerLifetimeValue);
router.get("/analytics/customers/segmentation", adminController.getCustomerSegmentation);

// Export - Phase 4
router.get("/export/sales", exportController.exportSalesReport);
router.get("/export/products", exportController.exportProductReport);
router.get("/export/customers", exportController.exportCustomerReport);

module.exports = router;
