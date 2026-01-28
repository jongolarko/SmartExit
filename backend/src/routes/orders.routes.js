const express = require("express");
const router = express.Router();
const auth = require("../middleware/auth.middleware");
const ordersController = require("../controllers/orders.controller");

// All routes require customer authentication
router.use(auth(["customer"]));

// GET /orders - Get user's orders
router.get("/", ordersController.getMyOrders);

// GET /orders/:id - Get order details
router.get("/:id", ordersController.getOrderDetails);

module.exports = router;
