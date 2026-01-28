const express = require("express");
const router = express.Router();
const adminController = require("../controllers/admin.controller");
const auth = require("../middleware/auth.middleware");

// All admin routes require admin role
router.use(auth(["admin"]));

// Dashboard
router.get("/dashboard", adminController.getDashboard);

// Orders
router.get("/orders", adminController.getOrders);
router.get("/orders/:id", adminController.getOrderDetails);

// Users
router.get("/users", adminController.getUsers);

// Security logs
router.get("/security-logs", adminController.getSecurityLogs);

// Products
router.get("/products", adminController.getProducts);
router.post("/products", adminController.createProduct);
router.put("/products/:id", adminController.updateProduct);
router.delete("/products/:id", adminController.deleteProduct);
router.post("/products/:id/stock", adminController.adjustStock);
router.get("/products/:id/history", adminController.getProductHistory);

// Inventory
router.get("/inventory/low-stock", adminController.getLowStockProducts);
router.get("/inventory/report", adminController.getInventoryReport);

module.exports = router;
