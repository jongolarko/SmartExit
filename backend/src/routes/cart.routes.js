const express = require("express");
const router = express.Router();
const cartController = require("../controllers/cart.controller");
const auth = require("../middleware/auth.middleware");
const { validate } = require("../middleware/validator.middleware");

// All cart routes require customer authentication
router.use(auth(["customer"]));

router.get("/", cartController.getCart);
router.post("/add", validate("addToCart"), cartController.addToCart);
router.put("/item/:itemId", validate("updateCartItem"), cartController.updateCartItem);
router.delete("/item/:itemId", cartController.removeCartItem);
router.delete("/", cartController.clearCart);

module.exports = router;
