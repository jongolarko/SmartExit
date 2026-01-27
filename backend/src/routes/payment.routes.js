const express = require("express");
const router = express.Router();
const paymentController = require("../controllers/payment.controller");
const auth = require("../middleware/auth.middleware");
const { validate } = require("../middleware/validator.middleware");

// Customer routes
router.post("/create-order", auth(["customer"]), paymentController.createOrder);
router.post("/verify", auth(["customer"]), validate("verifyPayment"), paymentController.verifyPayment);

// Webhook (no auth - verified by signature)
router.post("/webhook", paymentController.handleWebhook);

module.exports = router;
