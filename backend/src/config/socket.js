const { Server } = require("socket.io");
const jwt = require("jsonwebtoken");

let io = null;

// Store connected users by their user_id
const connectedUsers = new Map();

function initializeSocket(server) {
  io = new Server(server, {
    cors: {
      origin: "*",
      methods: ["GET", "POST"],
    },
  });

  // Authentication middleware for Socket.io
  io.use((socket, next) => {
    const token = socket.handshake.auth.token;
    if (!token) {
      return next(new Error("Authentication required"));
    }

    try {
      const decoded = jwt.verify(token, process.env.JWT_SECRET);
      socket.user = decoded;
      next();
    } catch (err) {
      return next(new Error("Invalid token"));
    }
  });

  io.on("connection", (socket) => {
    const userId = socket.user.user_id;
    const role = socket.user.role;

    // Store socket connection
    connectedUsers.set(userId, socket.id);
    console.log(`User connected: ${userId} (${role})`);

    // Join role-specific rooms
    socket.join(`role:${role}`);
    socket.join(`user:${userId}`);

    // Handle disconnection
    socket.on("disconnect", () => {
      connectedUsers.delete(userId);
      console.log(`User disconnected: ${userId}`);
    });

    // Customer subscribes to their cart updates
    if (role === "customer") {
      socket.join(`cart:${userId}`);
    }

    // Security personnel join security room
    if (role === "security") {
      socket.join("security:all");
    }

    // Admin joins admin room
    if (role === "admin") {
      socket.join("admin:all");
    }
  });

  return io;
}

function getIO() {
  if (!io) {
    throw new Error("Socket.io not initialized");
  }
  return io;
}

// Emit cart update to a specific user
function emitCartUpdate(userId, cartData) {
  if (io) {
    io.to(`cart:${userId}`).emit("cart:updated", cartData);
  }
}

// Emit exit request to security personnel
function emitExitRequest(exitData) {
  if (io) {
    io.to("security:all").emit("exit:request", exitData);
  }
}

// Emit exit decision to customer
function emitExitDecision(userId, decision) {
  if (io) {
    io.to(`user:${userId}`).emit("exit:decision", decision);
  }
}

// Emit new order notification to admin
function emitNewOrder(orderData) {
  if (io) {
    io.to("admin:all").emit("order:new", orderData);
  }
}

// Emit fraud alert to admin
function emitFraudAlert(alertData) {
  if (io) {
    io.to("admin:all").emit("fraud:alert", alertData);
  }
}

module.exports = {
  initializeSocket,
  getIO,
  emitCartUpdate,
  emitExitRequest,
  emitExitDecision,
  emitNewOrder,
  emitFraudAlert,
  connectedUsers,
};
