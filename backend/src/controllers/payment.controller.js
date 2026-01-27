const crypto = require("crypto");
const pool = require("../config/db");
const razorpay = require("../config/razorpay");
const { emitNewOrder } = require("../config/socket");
const { success, error } = require("../utils/response");
const logger = require("../utils/logger");

// POST /payment/create-order - Create Razorpay order
async function createOrder(req, res, next) {
  try {
    const userId = req.user.user_id;

    // Get cart total
    const totalRes = await pool.query(
      `SELECT SUM(ci.quantity * ci.price) AS total
       FROM carts c
       JOIN cart_items ci ON c.id = ci.cart_id
       WHERE c.user_id = $1 AND c.status = 'active'`,
      [userId]
    );

    const total = parseFloat(totalRes.rows[0].total || 0);

    if (total <= 0) {
      return error(res, "Cart is empty", 400);
    }

    // Create Razorpay order
    const rpOrder = await razorpay.orders.create({
      amount: Math.round(total * 100), // Convert to paise
      currency: "INR",
      receipt: `rcpt_${Date.now()}`,
      notes: {
        user_id: userId,
      },
    });

    // Create order in database
    const orderId = crypto.randomUUID();

    await pool.query(
      `INSERT INTO orders (id, user_id, razorpay_order_id, total_amount, status, created_at)
       VALUES ($1, $2, $3, $4, 'created', NOW())`,
      [orderId, userId, rpOrder.id, total]
    );

    logger.info(`Payment order created: ${orderId} for user ${userId}`);

    return success(res, {
      order_id: orderId,
      razorpay_order_id: rpOrder.id,
      key: process.env.RAZORPAY_KEY_ID,
      amount: rpOrder.amount,
      currency: rpOrder.currency,
      name: "SmartExit",
      description: "Store checkout",
    });
  } catch (err) {
    next(err);
  }
}

// POST /payment/verify - Verify Razorpay payment
async function verifyPayment(req, res, next) {
  try {
    const {
      razorpay_order_id,
      razorpay_payment_id,
      razorpay_signature,
      order_id,
    } = req.body;

    const userId = req.user.user_id;

    // Verify signature (always verify in all environments)
    const body = razorpay_order_id + "|" + razorpay_payment_id;
    const expectedSignature = crypto
      .createHmac("sha256", process.env.RAZORPAY_KEY_SECRET)
      .update(body)
      .digest("hex");

    if (expectedSignature !== razorpay_signature) {
      logger.warn(`Invalid payment signature for order ${order_id}`);
      return error(res, "Invalid payment signature", 400);
    }

    // Verify order belongs to user
    const orderRes = await pool.query(
      "SELECT * FROM orders WHERE id = $1 AND user_id = $2",
      [order_id, userId]
    );

    if (orderRes.rows.length === 0) {
      return error(res, "Order not found", 404);
    }

    const order = orderRes.rows[0];

    if (order.status === "paid") {
      return error(res, "Order already paid", 400);
    }

    // Start transaction
    const client = await pool.connect();

    try {
      await client.query("BEGIN");

      // Update order status
      await client.query(
        `UPDATE orders
         SET status = 'paid',
             razorpay_payment_id = $1,
             paid_at = NOW()
         WHERE id = $2`,
        [razorpay_payment_id, order_id]
      );

      // Get cart items and save to order_items
      const cartItems = await client.query(
        `SELECT ci.*, c.id as cart_id
         FROM carts c
         JOIN cart_items ci ON c.id = ci.cart_id
         WHERE c.user_id = $1 AND c.status = 'active'`,
        [userId]
      );

      for (const item of cartItems.rows) {
        await client.query(
          `INSERT INTO order_items (id, order_id, product_id, quantity, price)
           VALUES ($1, $2, $3, $4, $5)`,
          [
            crypto.randomUUID(),
            order_id,
            item.product_id,
            item.quantity,
            item.price,
          ]
        );

        // Decrease stock
        await client.query(
          `UPDATE products
           SET stock = GREATEST(0, stock - $1)
           WHERE id = $2 AND stock IS NOT NULL`,
          [item.quantity, item.product_id]
        );
      }

      // Mark cart as completed
      if (cartItems.rows.length > 0) {
        await client.query(
          "UPDATE carts SET status = 'completed' WHERE id = $1",
          [cartItems.rows[0].cart_id]
        );
      }

      await client.query("COMMIT");

      logger.info(`Payment verified for order ${order_id}`);

      // Emit new order notification to admin
      emitNewOrder({
        order_id,
        user_id: userId,
        amount: order.total_amount,
        items: cartItems.rows.length,
      });

      return success(res, {
        message: "Payment verified successfully",
        order_id,
      });
    } catch (err) {
      await client.query("ROLLBACK");
      throw err;
    } finally {
      client.release();
    }
  } catch (err) {
    next(err);
  }
}

// POST /webhooks/razorpay - Razorpay webhook handler
async function handleWebhook(req, res, next) {
  try {
    const webhookSecret = process.env.RAZORPAY_WEBHOOK_SECRET;

    // Verify webhook signature
    if (webhookSecret) {
      const signature = req.headers["x-razorpay-signature"];
      const expectedSignature = crypto
        .createHmac("sha256", webhookSecret)
        .update(JSON.stringify(req.body))
        .digest("hex");

      if (signature !== expectedSignature) {
        logger.warn("Invalid webhook signature");
        return res.status(400).json({ error: "Invalid signature" });
      }
    }

    const event = req.body.event;
    const payload = req.body.payload;

    logger.info(`Razorpay webhook received: ${event}`);

    switch (event) {
      case "payment.captured":
        // Payment was successful
        const paymentId = payload.payment.entity.id;
        const orderId = payload.payment.entity.order_id;

        await pool.query(
          `UPDATE orders
           SET status = 'paid', razorpay_payment_id = $1, paid_at = NOW()
           WHERE razorpay_order_id = $2 AND status != 'paid'`,
          [paymentId, orderId]
        );
        break;

      case "payment.failed":
        // Payment failed
        const failedOrderId = payload.payment.entity.order_id;
        await pool.query(
          `UPDATE orders SET status = 'failed' WHERE razorpay_order_id = $1`,
          [failedOrderId]
        );
        break;

      case "refund.created":
        // Refund initiated
        logger.info(`Refund created: ${payload.refund.entity.id}`);
        break;
    }

    return res.json({ received: true });
  } catch (err) {
    next(err);
  }
}

module.exports = {
  createOrder,
  verifyPayment,
  handleWebhook,
};
