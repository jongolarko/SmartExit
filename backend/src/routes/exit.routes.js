const express = require("express");
const router = express.Router();
const exitController = require("../controllers/exit.controller");
const auth = require("../middleware/auth.middleware");
const { validate } = require("../middleware/validator.middleware");

// Customer routes
router.post("/generate", auth(["customer"]), validate("generateExit"), exitController.generateExitToken);
router.get("/status/:token", auth(["customer"]), exitController.getExitStatus);

module.exports = router;
