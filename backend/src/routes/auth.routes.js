const express = require("express");
const router = express.Router();
const authController = require("../controllers/auth.controller");
const auth = require("../middleware/auth.middleware");
const { validate } = require("../middleware/validator.middleware");

// Public routes
router.post("/register", validate("register"), authController.register);
router.post("/verify-otp", validate("verifyOtp"), authController.verifyOtp);
router.post("/send-otp", authController.sendOtp);
router.post("/refresh-token", validate("refreshToken"), authController.refreshToken);

// Protected routes
router.post("/logout", auth(), authController.logout);
router.get("/me", auth(), authController.getProfile);

module.exports = router;
