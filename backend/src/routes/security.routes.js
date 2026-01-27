const express = require("express");
const router = express.Router();
const securityController = require("../controllers/security.controller");
const auth = require("../middleware/auth.middleware");
const { validate } = require("../middleware/validator.middleware");

// All security routes require security role
router.use(auth(["security", "admin"]));

router.post("/verify-qr", validate("verifyQr"), securityController.verifyQR);
router.post("/allow-exit", validate("allowExit"), securityController.allowExit);
router.get("/pending", securityController.getPendingExits);
router.get("/history", securityController.getHistory);

module.exports = router;
