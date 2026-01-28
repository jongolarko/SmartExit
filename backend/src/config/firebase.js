const admin = require("firebase-admin");
const logger = require("../utils/logger");

let firebaseApp = null;

/**
 * Initialize Firebase Admin SDK
 * Requires FIREBASE_PROJECT_ID, FIREBASE_CLIENT_EMAIL, FIREBASE_PRIVATE_KEY env vars
 */
function initializeFirebase() {
  if (firebaseApp) {
    return firebaseApp;
  }

  const projectId = process.env.FIREBASE_PROJECT_ID;
  const clientEmail = process.env.FIREBASE_CLIENT_EMAIL;
  const privateKey = process.env.FIREBASE_PRIVATE_KEY;

  if (!projectId || !clientEmail || !privateKey) {
    logger.warn(
      "Firebase not configured: missing FIREBASE_PROJECT_ID, FIREBASE_CLIENT_EMAIL, or FIREBASE_PRIVATE_KEY"
    );
    return null;
  }

  try {
    firebaseApp = admin.initializeApp({
      credential: admin.credential.cert({
        projectId,
        clientEmail,
        // Private key comes with escaped newlines from env, need to unescape
        privateKey: privateKey.replace(/\\n/g, "\n"),
      }),
    });

    logger.info("Firebase Admin SDK initialized successfully");
    return firebaseApp;
  } catch (err) {
    logger.error(`Failed to initialize Firebase: ${err.message}`);
    return null;
  }
}

/**
 * Get Firebase Messaging instance
 */
function getMessaging() {
  const app = initializeFirebase();
  if (!app) {
    return null;
  }
  return admin.messaging(app);
}

/**
 * Check if Firebase is available
 */
function isFirebaseConfigured() {
  return !!(
    process.env.FIREBASE_PROJECT_ID &&
    process.env.FIREBASE_CLIENT_EMAIL &&
    process.env.FIREBASE_PRIVATE_KEY
  );
}

module.exports = {
  initializeFirebase,
  getMessaging,
  isFirebaseConfigured,
};
