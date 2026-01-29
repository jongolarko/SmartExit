const express = require("express");
const router = express.Router();

const authRoutes = require("./auth.routes");
const cartRoutes = require("./cart.routes");
const paymentRoutes = require("./payment.routes");
const exitRoutes = require("./exit.routes");
const securityRoutes = require("./security.routes");
const adminRoutes = require("./admin.routes");
const ordersRoutes = require("./orders.routes");
const notificationsRoutes = require("./notifications.routes");
const searchRoutes = require("./search.routes");
const recommendationsRoutes = require("./recommendations.routes");
const insightsRoutes = require("./insights.routes");

router.use("/auth", authRoutes);
router.use("/cart", cartRoutes);
router.use("/payment", paymentRoutes);
router.use("/exit", exitRoutes);
router.use("/security", securityRoutes);
router.use("/admin", adminRoutes);
router.use("/orders", ordersRoutes);
router.use("/notifications", notificationsRoutes);
router.use("/search", searchRoutes);
router.use("/recommendations", recommendationsRoutes);
router.use("/insights", insightsRoutes);

module.exports = router;
