const { onRequest, onCall, HttpsError } = require("firebase-functions/v2/https");
const logger = require("firebase-functions/logger");

const { onDocumentCreated, onDocumentUpdated } = require("firebase-functions/v2/firestore");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const { GoogleAuth } = require("google-auth-library");
const crypto = require("crypto");
const { initializeApp } = require("firebase-admin/app");
const { getMessaging } = require("firebase-admin/messaging");
const { getFirestore, FieldValue, FieldPath } = require("firebase-admin/firestore");
const { getAuth } = require("firebase-admin/auth");
const { getStorage } = require("firebase-admin/storage");
// Note: User registration is handled client-side in AuthService._createUserProfile

initializeApp();
const db = getFirestore();
const auth = getAuth();
const storage = getStorage();

const DEFAULT_STORAGE_BUCKET = "love2learnsign-1914ce.firebasestorage.app";
const ANDROID_PACKAGE_NAME = "com.love2learnsign.app";

// Notifications strategy:
// - Production: send a DAILY digest of new words (to avoid spam and to work app-closed)
// - Optional: per-word push disabled by default
const ENABLE_PER_WORD_NEW_WORD_PUSH = false;

/**
 * Normalize roles so premium state is consistent across Firestore + Custom Claims.
 * Rule: `paidUser` and `freeUser` are mutually exclusive.
 * Rule: `admin` implies `paidUser`.
 * - If `paidUser` is present => remove `freeUser`
 * - Otherwise => ensure `freeUser` is present (baseline role for non-premium users)
 *
 * Other roles (admin/editor/teacher/...) are preserved.
 */
function normalizeRoles(inputRoles) {
  const roles = Array.isArray(inputRoles) ? inputRoles : [];
  const set = new Set(
    roles
      .map((r) => String(r).trim())
      .filter((r) => r.length > 0)
  );

  // Admins are always premium (global) for the co-brand SaaS model.
  if (set.has("admin")) {
    set.add("paidUser");
  }

  if (set.has("paidUser")) {
    set.delete("freeUser");
  } else {
    set.add("freeUser");
  }

  return Array.from(set);
}

async function findUserDocRefByUid(uid) {
  const qs = await db.collection("users").where("uid", "==", uid).limit(1).get();
  if (!qs.empty) return qs.docs[0].ref;
  // Fallback: legacy docId == uid
  return db.collection("users").doc(uid);
}

async function setUserRolesInAuth(uid, roles) {
  const user = await auth.getUser(uid);
  const existing = user.customClaims || {};
  await auth.setCustomUserClaims(uid, { ...existing, roles });
}

async function verifyPlaySubscription({ productId, purchaseToken }) {
  // Uses Cloud Functions runtime service account. You must grant this service account
  // access in Play Console (Users & permissions) and enable Google Play Android Developer API.
  const googleAuth = new GoogleAuth({
    scopes: ["https://www.googleapis.com/auth/androidpublisher"],
  });
  const client = await googleAuth.getClient();
  const accessToken = await client.getAccessToken();
  const token = accessToken?.token;
  if (!token) {
    throw new Error("Could not obtain Google API access token");
  }

  const url =
    `https://androidpublisher.googleapis.com/androidpublisher/v3/applications/` +
    `${encodeURIComponent(ANDROID_PACKAGE_NAME)}/purchases/subscriptions/` +
    `${encodeURIComponent(productId)}/tokens/${encodeURIComponent(purchaseToken)}`;

  const res = await fetch(url, {
    method: "GET",
    headers: {
      Authorization: `Bearer ${token}`,
      "Content-Type": "application/json",
    },
  });
  if (!res.ok) {
    const text = await res.text();
    const err = new Error(`Play API error (${res.status}): ${text}`);
    err.status = res.status;
    throw err;
  }
  return await res.json();
}

function tryParseStorageObjectFromUrl(url) {
  if (!url || typeof url !== "string") return null;
  const s = url.trim();
  if (!s) return null;

  // gs://bucket/path/to/object
  if (s.startsWith("gs://")) {
    const without = s.substring("gs://".length);
    const firstSlash = without.indexOf("/");
    if (firstSlash === -1) return null;
    return {
      bucket: without.substring(0, firstSlash),
      objectPath: without.substring(firstSlash + 1),
    };
  }

  try {
    const u = new URL(s);

    // https://firebasestorage.googleapis.com/v0/b/<bucket>/o/<encodedPath>?...
    if (u.hostname === "firebasestorage.googleapis.com") {
      const parts = u.pathname.split("/").filter(Boolean); // [v0, b, <bucket>, o, <encodedPath>]
      const bIndex = parts.indexOf("b");
      const oIndex = parts.indexOf("o");
      if (bIndex !== -1 && oIndex !== -1 && parts[bIndex + 1] && parts[oIndex + 1]) {
        const bucket = parts[bIndex + 1];
        const encodedPath = parts[oIndex + 1];
        return { bucket, objectPath: decodeURIComponent(encodedPath) };
      }
    }

    // https://storage.googleapis.com/<bucket>/<path>
    if (u.hostname === "storage.googleapis.com") {
      const parts = u.pathname.split("/").filter(Boolean);
      if (parts.length >= 2) {
        const bucket = parts[0];
        const objectPath = parts.slice(1).join("/");
        return { bucket, objectPath };
      }
    }

    // https://<bucket>.storage.googleapis.com/<path>
    if (u.hostname.endsWith(".storage.googleapis.com")) {
      const bucket = u.hostname.replace(".storage.googleapis.com", "");
      const objectPath = u.pathname.replace(/^\/+/, "");
      if (bucket && objectPath) return { bucket, objectPath };
    }
  } catch (_) {
    // not a URL
  }

  return null;
}

function collectDictionaryMediaUrls(wordData) {
  const urls = [];

  const maybePush = (v) => {
    if (typeof v === "string" && v.trim()) urls.push(v.trim());
  };

  // New schema
  maybePush(wordData.imageFlashcard);
  if (Array.isArray(wordData.variants)) {
    for (const v of wordData.variants) {
      if (!v || typeof v !== "object") continue;
      // Canonical (new) fields
      maybePush(v.videos_360);
      maybePush(v.videos_480);
      maybePush(v.videos_720);
      // Legacy (temporary)
      maybePush(v.videoUrl);
      maybePush(v.videoUrlSD);
      maybePush(v.videoUrlHD);
      maybePush(v.videoThumbnail);
      maybePush(v.videoThumbnailSmall);
    }
  }

  // Legacy/top-level fallbacks (if present)
  // Canonical (new) top-level (optional if some code writes them there)
  maybePush(wordData.videos_360);
  maybePush(wordData.videos_480);
  maybePush(wordData.videos_720);
  maybePush(wordData.videoUrl);
  maybePush(wordData.videoUrlSD);
  maybePush(wordData.videoUrlHD);
  maybePush(wordData.videoThumbnail);
  maybePush(wordData.videoThumbnailSmall);

  return urls;
}

async function deleteCollectionRecursive(collectionRef) {
  const snapshot = await collectionRef.get();
  for (const doc of snapshot.docs) {
    await deleteDocumentRecursive(doc.ref);
  }
}

async function deleteDocumentRecursive(docRef) {
  const subcollections = await docRef.listCollections();
  for (const sub of subcollections) {
    await deleteCollectionRecursive(sub);
  }
  await docRef.delete();
}

// Daily digest: send summary of new words added in the last 24h.
// Requires Cloud Scheduler enabled on the Firebase project.
exports.sendDailyNewWordsDigest = onSchedule(
  {
    region: "us-central1",
    // Daily at 12:00 UTC. Adjust as desired (e.g., Europe/Paris).
    schedule: "0 12 * * *",
    timeZone: "Etc/UTC",
  },
  async () => {
    const tenantId = "l2l-bdsl";
    const since = new Date(Date.now() - 24 * 60 * 60 * 1000);

    try {
      const snap = await db
        .collection("tenants")
        .doc(tenantId)
        .collection("concepts")
        .where("addedAt", ">=", since)
        .orderBy("addedAt", "desc")
        .limit(20)
        .get();

      if (snap.empty) {
        logger.info("sendDailyNewWordsDigest: no new words in last 24h");
        return;
      }

      const docs = snap.docs.slice(0, 5);
      const lines = docs
        .map((d) => {
          const w = d.data() || {};
          const en = (w.english || "New word").toString();
          const bn = (w.bengali || "").toString();
          return bn ? `📘 ${en} — ${bn}` : `📘 ${en}`;
        })
        .join("\n");

      const count = snap.size;
      const suffix = count > docs.length ? `\n… +${count - docs.length} more` : "";

      const message = {
        notification: {
          title: "New words added!",
          body: `${lines}${suffix}`,
        },
        data: {
          kind: "new_words_digest",
          tenantId,
        },
        topic: "new_words",
      };

      await getMessaging().send(message);
      logger.info("sendDailyNewWordsDigest: push sent", { count });
    } catch (error) {
      logger.error("sendDailyNewWordsDigest: failed", error);
    }
  }
);

exports.notifyNewWord = onDocumentCreated("tenants/{tenantId}/concepts/{conceptId}", async (event) => {
  const snapshot = event.data;
  if (!snapshot) {
    console.log("No data in snapshot.");
    return;
  }

  const { tenantId, conceptId } = event.params || {};
  // Only notify for the Love2Learn default tenant (avoid spamming in white-label tenants).
  if (tenantId !== "l2l-bdsl") return;

  const newWord = snapshot.data();

  // Ensure addedAt timestamp is set
  const ref = snapshot.ref;
  if (!newWord.addedAt) {
    await ref.update({ addedAt: FieldValue.serverTimestamp() });
  }

  // Per-word push disabled by default (daily digest is used in production).
  if (!ENABLE_PER_WORD_NEW_WORD_PUSH) return;

  const english = newWord.english || "New word";
  const bengali = newWord.bengali || "";

  const message = {
    notification: {
      title: "New word added!",
      body: `📘 ${english} — ${bengali} just got added to your Love to Learn Sign App!`,
    },
    topic: "new_words",
  };

  try {
    await getMessaging().send(message);
    console.log("Push notification sent.");
  } catch (error) {
    console.error("Error sending notification:", error);
  }
});

/**
 * Cloud Function: updateUserRoles
 * Triggered when a user document in /users/{userId} is updated
 * Updates Firebase Custom Claims with the user's roles array
 * NO EMAIL IS SENT - emails are only sent via sendUserRoleNotification callable function
 */
exports.updateUserRoles = onDocumentUpdated(
  {
    region: "us-central1",
  },
  "users/{userId}",
  async (event) => {
    // In Firebase Functions v2, onDocumentUpdated provides:
    // event.data.before - DocumentSnapshot before the change
    // event.data.after - DocumentSnapshot after the change
    // event.params - URL parameters (userId)

    const documentId = event.params.userId; // This is the document ID (could be [name]__[UID] or [UID])

    console.log('🔍 updateUserRoles: Event received');
    console.log('🔍 updateUserRoles: Document ID:', documentId);
    console.log('🔍 updateUserRoles: event type:', typeof event);
    console.log('🔍 updateUserRoles: event.data type:', typeof event.data);
    console.log('🔍 updateUserRoles: event.data.before exists:', event.data?.before?.exists);
    console.log('🔍 updateUserRoles: event.data.after exists:', event.data?.after?.exists);

    if (!event.data || !event.data.after || !event.data.after.exists) {
      console.error('❌ updateUserRoles: event.data.after is missing or document does not exist');
      return null;
    }

    // Get data from snapshots safely
    const beforeData = event.data.before?.exists ? event.data.before.data() : {};
    const afterData = event.data.after.data();

    console.log('🔍 updateUserRoles: beforeData:', JSON.stringify(beforeData));
    console.log('🔍 updateUserRoles: afterData:', JSON.stringify(afterData));

    // Get UID from document data (new format) or use document ID (old format)
    let uid = afterData.uid;

    // If UID is missing in data, try to extract it from document ID (format: Name__UID)
    if (!uid) {
      if (documentId.includes('__')) {
        const parts = documentId.split('__');
        uid = parts[parts.length - 1];
        console.log(`⚠️ updateUserRoles: UID missing in data, extracted from ID: ${uid}`);
      } else {
        uid = documentId;
        console.log(`⚠️ updateUserRoles: UID missing in data, using document ID: ${uid}`);
      }
    }

    const newRoles = Array.isArray(afterData.roles) ? afterData.roles : [];
    const oldRoles = Array.isArray(beforeData.roles) ? beforeData.roles : [];
    const normalizedRoles = normalizeRoles(newRoles);
    const normalizedDiffers =
      JSON.stringify([...normalizedRoles].sort()) !==
      JSON.stringify([...newRoles].map((r) => String(r)).sort());

    console.log(`🔍 updateUserRoles: Document ID: ${documentId}, UID: ${uid}`);
    console.log(`🔍 updateUserRoles: Old roles:`, oldRoles);
    console.log(`🔍 updateUserRoles: New roles:`, newRoles);
    if (normalizedDiffers) {
      console.log(`ℹ️ updateUserRoles: Normalized roles (enforcing freeUser/paidUser exclusivity):`, normalizedRoles);
    }

    // Always update Custom Claims to ensure they match Firestore (even if empty)
    if (newRoles.length === 0) {
      console.log(`ℹ️ updateUserRoles: Roles list is empty for user ${uid} (baseline roles will be applied)`);
    }

    // Check if roles changed
    const rolesChanged =
      JSON.stringify([...normalizedRoles].sort()) !==
      JSON.stringify([...normalizeRoles(oldRoles)].sort());

    try {
      // Optional (recommended): write normalized roles back to Firestore so Admin Panel never shows a non-normalized mix.
      // Idempotent: second trigger run will see roles already normalized and will not rewrite.
      if (normalizedDiffers) {
        await event.data.after.ref.update({ roles: normalizedRoles });
      }

      console.log(`🔄 updateUserRoles: Setting Custom Claims for user ${uid} with roles:`, normalizedRoles);

      // Update Custom Claims using the UID from document data
      await auth.setCustomUserClaims(uid, {
        roles: normalizedRoles,
      });

      console.log(`✅ updateUserRoles: Successfully set Custom Claims for user ${uid} (document: ${documentId}) with roles:`, normalizedRoles);

      if (rolesChanged) {
        // Log the change only if roles actually changed
        await db.collection('roleLogs').add({
          userId: uid,
          documentId: documentId,
          oldRoles: oldRoles,
          newRoles: normalizedRoles,
          updatedBy: 'cloud-function',
          updatedAt: FieldValue.serverTimestamp(),
        });
        console.log(`📝 updateUserRoles: Logged role change for user ${uid}`);
      }

      return null;
    } catch (error) {
      console.error(`❌ updateUserRoles: Error updating Custom Claims for user ${uid} (document: ${documentId}):`, error);
      console.error(`❌ updateUserRoles: Error message:`, error.message);
      console.error(`❌ updateUserRoles: Error stack:`, error.stack);
      throw error;
    }
  }
);

/**
 * Callable Cloud Function to set Custom Claims directly
 * This is called from the Flutter app to ensure Custom Claims are set before Firestore operations
 */
exports.setCustomClaims = onCall(
  {
    region: "us-central1",
    cors: true,
  },
  async (request) => {
    const { userId, roles } = request.data;

    // Verify the caller is authenticated
    if (!request.auth) {
      throw new HttpsError('unauthenticated', 'User must be authenticated');
    }

    // Verify the caller has admin role via Custom Claims (primary method)
    let callerRoles = [];
    try {
      const callerUser = await auth.getUser(request.auth.uid);
      callerRoles = Array.isArray(callerUser.customClaims?.roles) ? callerUser.customClaims.roles : [];
    } catch (error) {
      console.error('Error getting caller user:', error);
      throw new HttpsError('internal', 'Error verifying admin access');
    }

    // If Custom Claims not set, fallback to Firestore check
    if (!callerRoles.includes('admin')) {
      const callerDoc = await db.collection('users')
        .where('uid', '==', request.auth.uid)
        .limit(1)
        .get();

      if (callerDoc.empty) {
        throw new HttpsError('permission-denied', 'User document not found');
      }

      const callerData = callerDoc.docs[0].data();
      const firestoreRoles = Array.isArray(callerData.roles) ? callerData.roles : [];

      if (!firestoreRoles.includes('admin')) {
        throw new HttpsError('permission-denied', 'Only admins can set Custom Claims');
      }
    }

    try {
      const normalizedRoles = normalizeRoles(roles || []);
      console.log(`🔄 setCustomClaims: Setting Custom Claims for user ${userId} with roles:`, normalizedRoles);

      // Set Custom Claims
      await auth.setCustomUserClaims(userId, {
        roles: normalizedRoles,
      });

      console.log(`✅ setCustomClaims: Successfully set Custom Claims for user ${userId} with roles:`, normalizedRoles);

      return { success: true, userId, roles: normalizedRoles };
    } catch (error) {
      console.error(`❌ setCustomClaims: Error setting Custom Claims for user ${userId}:`, error);
      throw new HttpsError('internal', `Failed to set Custom Claims: ${error.message}`);
    }
  }
);

/**
 * Callable: verifyPlaySubscription (Android)
 *
 * Why this exists:
 * - Firestore rules prevent clients from updating `roles` (by design).
 * - We must verify purchase server-side, then update Firestore + Custom Claims.
 *
 * Client passes:
 * - productId: e.g. premium_monthly / premium_yearly
 * - purchaseToken: from Billing (PurchaseDetails.verificationData.serverVerificationData)
 */
exports.verifyPlaySubscription = onCall(
  {
    region: "us-central1",
    cors: true,
  },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "User must be authenticated");
    }

    const { tenantId, productId, purchaseToken, platform } = request.data || {};
    if (!tenantId || typeof tenantId !== "string") {
      throw new HttpsError("invalid-argument", "tenantId is required");
    }
    if (!productId || typeof productId !== "string") {
      throw new HttpsError("invalid-argument", "productId is required");
    }
    if (!purchaseToken || typeof purchaseToken !== "string") {
      throw new HttpsError("invalid-argument", "purchaseToken is required");
    }
    if (platform && platform !== "android") {
      throw new HttpsError("failed-precondition", "Only Android is supported for now");
    }

    const uid = request.auth.uid;
    const tenant = tenantId.trim();
    if (!tenant) {
      throw new HttpsError("invalid-argument", "tenantId is required");
    }

    // Tenant-safe SKU validation:
    // Prevent a user from using a paid productId from tenant A to unlock tenant B.
    // Source of truth: /tenants/{tenantId}/monetization/config (iapProducts.*)
    let subscriptionType = productId.includes("yearly") ? "yearly" : "monthly";
    try {
      const cfgSnap = await db
        .collection("tenants")
        .doc(tenant)
        .collection("monetization")
        .doc("config")
        .get();

      const cfg = cfgSnap.exists ? cfgSnap.data() || {} : {};
      const iap = cfg && typeof cfg.iapProducts === "object" ? cfg.iapProducts : {};

      const monthly = String(iap.monthlyProductIdAndroid || iap.monthlyProductId || "").trim();
      const yearly = String(iap.yearlyProductIdAndroid || iap.yearlyProductId || "").trim();

      const allowed = new Set([monthly, yearly].filter(Boolean));
      if (allowed.size > 0) {
        if (!allowed.has(productId)) {
          throw new HttpsError(
            "permission-denied",
            `productId is not allowed for tenantId=${tenant}`
          );
        }
        // Determine type from the configured mapping (more reliable than string contains).
        if (productId === yearly) subscriptionType = "yearly";
        if (productId === monthly) subscriptionType = "monthly";
      } else {
        // Backward-compatible fallback for the default tenant if config isn't set yet.
        // (Helps avoid breaking existing deployments during migration.)
        if (tenant === "l2l-bdsl") {
          const legacyAllowed = new Set(["premium_monthly", "premium_yearly"]);
          if (!legacyAllowed.has(productId)) {
            throw new HttpsError(
              "failed-precondition",
              `No IAP products configured for tenantId=${tenant}. Set tenants/${tenant}/monetization/config`
            );
          }
        } else {
          throw new HttpsError(
            "failed-precondition",
            `No IAP products configured for tenantId=${tenant}. Set tenants/${tenant}/monetization/config`
          );
        }
      }
    } catch (e) {
      // Preserve explicit HttpsError, wrap other errors.
      if (e instanceof HttpsError) throw e;
      console.error("verifyPlaySubscription: tenant SKU validation failed", e);
      throw new HttpsError("internal", `Tenant SKU validation failed: ${e?.message || e}`);
    }

    let purchase;
    try {
      purchase = await verifyPlaySubscription({ productId, purchaseToken });
    } catch (e) {
      console.error("verifyPlaySubscription: Play verify failed", e);
      throw new HttpsError("internal", `Play verification failed: ${e.message || e}`);
    }

    const expiryTimeMillis = Number(purchase.expiryTimeMillis || 0);
    const now = Date.now();
    const active = expiryTimeMillis > now;

    // Compute renewal date based on Play's expiry (more accurate than 'now + 30d').
    const renewalDate = expiryTimeMillis ? new Date(expiryTimeMillis) : null;

    // Option A: store per-tenant entitlement (source of truth for Premium gating).
    const purchaseTokenHash = crypto
      .createHash("sha256")
      .update(String(purchaseToken))
      .digest("hex")
      .substring(0, 32);

    const entRef = db.collection("users").doc(uid).collection("entitlements").doc(tenant);
    await db.runTransaction(async (tx) => {
      const snap = await tx.get(entRef);
      const existing = snap.exists ? (snap.data() || {}) : {};
      const createdAt = snap.exists && existing.createdAt ? existing.createdAt : FieldValue.serverTimestamp();

      // If a tenant admin granted complimentary premium, keep it even if the store purchase expires.
      const manualActive = existing.manualActive === true;

      // Store purchase fields (do not overwrite manual fields).
      const purchaseActive = active;
      const purchaseValidUntil = renewalDate ? renewalDate : null;
      const purchasePlatform = "android";
      const purchaseSubscriptionType = subscriptionType;
      const purchaseProductId = productId;

      const effectiveActive = manualActive || purchaseActive;
      const effectiveValidUntil = manualActive ? null : purchaseValidUntil;
      const platformEffective = manualActive ? "manual" : purchasePlatform;
      const subscriptionTypeEffective = manualActive ? "complimentary" : purchaseSubscriptionType;

      tx.set(
        entRef,
        {
          uid,
          tenantId: tenant,
          // Backward compatible top-level fields (effective):
          productId: purchaseProductId,
          subscriptionType: subscriptionTypeEffective,
          platform: platformEffective,
          active: effectiveActive,
          validUntil: effectiveValidUntil,

          // Preserve both sources explicitly:
          manualActive,
          purchaseActive,
          purchaseValidUntil,
          purchasePlatform,
          purchaseSubscriptionType,
          purchaseProductId,

          purchaseTokenHash,
          createdAt,
          updatedAt: FieldValue.serverTimestamp(),
        },
        { merge: true }
      );
    });

    // Backward-compatible global premium state (default tenant only):
    // - Keep /users subscription_* fields in sync so reconcileSubscriptionRoles can work.
    // - Update Custom Claims roles (paidUser/freeUser) so the app badge updates immediately.
    let rolesUpdated = null;
    if (tenant === "l2l-bdsl") {
      try {
        const userRef = await findUserDocRefByUid(uid);
        const userSnap = await userRef.get();
        const data = userSnap.exists ? userSnap.data() || {} : {};
        const currentRoles = Array.isArray(data.roles) ? data.roles : [];
        const set = new Set(currentRoles.map((r) => String(r)));

        if (active) set.add("paidUser");
        else set.delete("paidUser");

        const newRoles = normalizeRoles(Array.from(set));

        const update = {
          uid,
          roles: newRoles,
          subscription_active: active,
          subscription_type: subscriptionType,
          subscription_platform: "android",
          subscription_product_id: productId,
          subscription_renewal_date: renewalDate ? renewalDate : null,
          updatedAt: FieldValue.serverTimestamp(),
        };

        // Preserve existing createdAt if present; otherwise set it.
        if (!data.createdAt) {
          update.createdAt = FieldValue.serverTimestamp();
        }

        await userRef.set(update, { merge: true });
        await setUserRolesInAuth(uid, newRoles);
        rolesUpdated = newRoles;
      } catch (e) {
        console.error("verifyPlaySubscription: failed to update global roles/claims", e);
        // Non-fatal: entitlement + tenant billing still updated.
      }
    }

    // Keep tenant member doc in sync for tenant-scoped Admin Panel + filters.
    const tenantRef = db.collection("tenants").doc(tenant);
    const memberRef = tenantRef.collection("members").doc(uid);
    const userTenantsRef = db.collection("userTenants").doc(uid);
    // Billing is derived from the entitlement doc (effective fields), so manual grants are respected.

    await db.runTransaction(async (tx) => {
      const entSnap = await tx.get(entRef);
      const ent = entSnap.exists ? (entSnap.data() || {}) : {};
      const isComplimentary = ent.manualActive === true || ent.platform === "manual" || ent.subscriptionType === "complimentary";
      const billing = {
        isPremium: ent.active === true,
        isComplimentary,
        subscriptionType: ent.subscriptionType || null,
        validUntil: ent.validUntil || null,
        productId: ent.productId || null,
        platform: ent.platform || null,
      };

      const memberSnap = await tx.get(memberRef);
      const createdAt =
        memberSnap.exists && memberSnap.data()?.createdAt ? memberSnap.data().createdAt : FieldValue.serverTimestamp();
      const existingRole = memberSnap.exists ? (memberSnap.data()?.role ?? "viewer") : "viewer";
      const existingStatus = memberSnap.exists ? (memberSnap.data()?.status ?? "active") : "active";

      tx.set(
        memberRef,
        {
          uid,
          role: existingRole,
          status: existingStatus,
          billing,
          updatedAt: FieldValue.serverTimestamp(),
          createdAt,
        },
        { merge: true }
      );

      tx.set(
        userTenantsRef,
        {
          tenants: {
            [tenant]: { role: existingRole, status: existingStatus },
          },
          updatedAt: FieldValue.serverTimestamp(),
        },
        { merge: true }
      );
    });

    return {
      success: true,
      active,
      renewalDate: renewalDate ? renewalDate.toISOString() : null,
      tenantId: tenant,
      productId,
      rolesUpdated,
    };
  }
);

/**
 * Callable: joinTenant
 *
 * Purpose:
 * - Allow a signed-in user to join a tenant without opening client-side writes to
 *   tenants/{tenantId}/members/{uid} or userTenants/{uid}.
 *
 * Behavior:
 * - If tenant is public => user can join as viewer.
 * - If tenant is private => only platform admins can join users (for now).
 * - Denormalizes basic profile fields into the membership doc for tenant-admin UI.
 */
exports.joinTenant = onCall(
  {
    region: "us-central1",
    cors: true,
  },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "User must be authenticated");
    }

    const uid = request.auth.uid;
    const tenantId = (request.data?.tenantId ?? "").toString().trim();
    if (!tenantId) {
      throw new HttpsError("invalid-argument", "tenantId is required");
    }

    // Load tenant doc (must exist).
    const tenantRef = db.collection("tenants").doc(tenantId);
    const tenantSnap = await tenantRef.get();
    if (!tenantSnap.exists) {
      throw new HttpsError("not-found", "Tenant not found");
    }

    const tenantData = tenantSnap.data() || {};
    const visibility = (tenantData.visibility ?? "public").toString();
    const isPublic = visibility !== "private";

    // For private tenants, require platform admin (simple + safe).
    if (!isPublic) {
      const platformMember = await db
        .collection("platform")
        .doc("platform")
        .collection("members")
        .doc(uid)
        .get();
      if (!platformMember.exists) {
        throw new HttpsError("permission-denied", "Tenant is private");
      }
    }

    // Pull user profile (best-effort) for denormalization.
    let profile = {};
    try {
      const authUser = await auth.getUser(uid);
      const providers = Array.isArray(authUser.providerData)
        ? authUser.providerData.map((p) => String(p.providerId || "").trim()).filter(Boolean)
        : [];
      profile.signInProvider = providers.includes("google.com")
        ? "google.com"
        : (providers[0] || null);
      profile.email = authUser.email || null;
      profile.displayName = authUser.displayName || null;
    } catch (_) {
      // ignore
    }
    try {
      const userRef = await findUserDocRefByUid(uid);
      const userSnap = await userRef.get();
      const u = userSnap.exists ? userSnap.data() || {} : {};
      profile.countryCode = u.countryCode ?? u.country ?? u.country_code ?? null;
      profile.hearingStatus = u.hearingStatus ?? u.hearing_status ?? u.userType ?? null;
      profile.createdAt = u.createdAt ?? null;
    } catch (_) {
      // ignore
    }

    // Best-effort: include billing info from entitlements for tenant admin panel filters.
    let billing = {};
    try {
      const entSnap = await db.collection("users").doc(uid).collection("entitlements").doc(tenantId).get();
      const ent = entSnap.exists ? entSnap.data() || {} : {};
      const activeEnt = ent.active === true;
      const validUntil = ent.validUntil || null;
      const isComplimentary = ent.manualActive === true || ent.platform === "manual" || ent.subscriptionType === "complimentary";
      billing = {
        isPremium: activeEnt,
        isComplimentary,
        subscriptionType: ent.subscriptionType || null,
        validUntil,
        productId: ent.productId || null,
        platform: ent.platform || null,
      };
    } catch (_) {
      // ignore
    }

    // Write membership + index.
    const memberRef = tenantRef.collection("members").doc(uid);
    const userTenantsRef = db.collection("userTenants").doc(uid);

    await db.runTransaction(async (tx) => {
      const memberSnap = await tx.get(memberRef);
      const existingRole = memberSnap.exists ? (memberSnap.data()?.role ?? "viewer") : "viewer";
      const existingStatus = memberSnap.exists ? (memberSnap.data()?.status ?? "active") : "active";
      const createdAt = memberSnap.exists && memberSnap.data()?.createdAt ? memberSnap.data().createdAt : FieldValue.serverTimestamp();

      tx.set(
        memberRef,
        {
          uid,
          role: existingRole,
          status: existingStatus,
          profile,
          billing,
          updatedAt: FieldValue.serverTimestamp(),
          createdAt,
        },
        { merge: true }
      );

      tx.set(
        userTenantsRef,
        {
          tenants: {
            [tenantId]: { role: existingRole, status: existingStatus },
          },
          updatedAt: FieldValue.serverTimestamp(),
        },
        { merge: true }
      );
    });

    return { success: true, tenantId, uid };
  }
);

/**
 * Callable: setTenantMemberRole
 *
 * Purpose:
 * - Tenant admins/owners can manage roles for members of THEIR tenant.
 * - Keeps userTenants/{uid} index in sync.
 */
exports.setTenantMemberRole = onCall(
  {
    region: "us-central1",
    cors: true,
  },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "User must be authenticated");
    }

    const callerUid = request.auth.uid;
    const tenantId = (request.data?.tenantId ?? "").toString().trim();
    const targetUid = (request.data?.targetUid ?? "").toString().trim();
    const role = (request.data?.role ?? "").toString().trim().toLowerCase();
    const status = (request.data?.status ?? "active").toString().trim().toLowerCase();

    if (!tenantId) throw new HttpsError("invalid-argument", "tenantId is required");
    if (!targetUid) throw new HttpsError("invalid-argument", "targetUid is required");
    if (!role) throw new HttpsError("invalid-argument", "role is required");

    const allowedRoles = new Set(["viewer", "analyst", "editor", "admin", "owner"]);
    const allowedStatus = new Set(["active", "inactive"]);
    if (!allowedRoles.has(role)) throw new HttpsError("invalid-argument", "Invalid role");
    if (!allowedStatus.has(status)) throw new HttpsError("invalid-argument", "Invalid status");

    // Authorize: platform admin OR tenant owner/admin.
    let isPlatformAdmin = false;
    try {
      const platform = await db
        .collection("platform")
        .doc("platform")
        .collection("members")
        .doc(callerUid)
        .get();
      isPlatformAdmin = platform.exists;
    } catch (_) {}

    if (!isPlatformAdmin) {
      const callerMember = await db
        .collection("tenants")
        .doc(tenantId)
        .collection("members")
        .doc(callerUid)
        .get();
      const callerRole = (callerMember.data()?.role ?? "").toString().trim().toLowerCase();
      if (!(callerRole === "owner" || callerRole === "admin")) {
        throw new HttpsError("permission-denied", "Caller is not tenant admin");
      }
    }

    const tenantRef = db.collection("tenants").doc(tenantId);
    const memberRef = tenantRef.collection("members").doc(targetUid);
    const userTenantsRef = db.collection("userTenants").doc(targetUid);

    // Best-effort denormalization for admin UI.
    let profile = {};
    try {
      const authUser = await auth.getUser(targetUid);
      const providers = Array.isArray(authUser.providerData)
        ? authUser.providerData.map((p) => String(p.providerId || "").trim()).filter(Boolean)
        : [];
      // Prefer showing google.com if linked; otherwise pick first provider (e.g. password).
      profile.signInProvider = providers.includes("google.com")
        ? "google.com"
        : (providers[0] || null);
      profile.email = authUser.email || null;
      profile.displayName = authUser.displayName || null;
    } catch (_) {
      // ignore
    }
    try {
      const userRef = await findUserDocRefByUid(targetUid);
      const userSnap = await userRef.get();
      const u = userSnap.exists ? userSnap.data() || {} : {};
      profile.countryCode = u.countryCode ?? u.country ?? u.country_code ?? null;
      profile.hearingStatus = u.hearingStatus ?? u.hearing_status ?? u.userType ?? null;
      profile.createdAt = u.createdAt ?? null;
    } catch (_) {
      // ignore
    }

    // Best-effort billing sync for tenant admin panel filters.
    let billing = {};
    try {
      const entSnap = await db.collection("users").doc(targetUid).collection("entitlements").doc(tenantId).get();
      const ent = entSnap.exists ? entSnap.data() || {} : {};
      const isComplimentary = ent.manualActive === true || ent.platform === "manual" || ent.subscriptionType === "complimentary";
      billing = {
        isPremium: ent.active === true,
        isComplimentary,
        subscriptionType: ent.subscriptionType || null,
        validUntil: ent.validUntil || null,
        productId: ent.productId || null,
        platform: ent.platform || null,
      };
    } catch (_) {
      // ignore
    }

    await db.runTransaction(async (tx) => {
      const snap = await tx.get(memberRef);
      const createdAt = snap.exists && snap.data()?.createdAt ? snap.data().createdAt : FieldValue.serverTimestamp();
      tx.set(
        memberRef,
        {
          uid: targetUid,
          role,
          status,
          profile,
          billing,
          updatedAt: FieldValue.serverTimestamp(),
          createdAt,
        },
        { merge: true }
      );

      tx.set(
        userTenantsRef,
        {
          tenants: {
            [tenantId]: { role, status },
          },
          updatedAt: FieldValue.serverTimestamp(),
        },
        { merge: true }
      );
    });

    return { success: true, tenantId, targetUid, role, status };
  }
);

/**
 * Callable: setTenantMemberAccess
 *
 * Purpose:
 * - Tenant owners/admins can grant per-tenant feature access (e.g. JW) and
 *   complimentary premium (manual entitlement) WITHOUT changing global roles.
 *
 * Data model:
 * - tenants/{tenantId}/members/{uid}.featureRoles: ['jw', ...]
 * - users/{uid}/entitlements/{tenantId}:
 *     - manualActive: boolean
 *     - purchaseActive/purchaseValidUntil/... (kept from store purchases)
 *     - active/validUntil/platform/subscriptionType (effective, derived)
 */
exports.setTenantMemberAccess = onCall(
  {
    region: "us-central1",
    cors: true,
  },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "User must be authenticated");
    }

    const callerUid = request.auth.uid;
    const tenantId = (request.data?.tenantId ?? "").toString().trim();
    const targetUid = (request.data?.targetUid ?? "").toString().trim();
    const jw = request.data?.jw;
    const premium = request.data?.premium;

    if (!tenantId) throw new HttpsError("invalid-argument", "tenantId is required");
    if (!targetUid) throw new HttpsError("invalid-argument", "targetUid is required");
    if (jw !== undefined && typeof jw !== "boolean") {
      throw new HttpsError("invalid-argument", "jw must be boolean");
    }
    if (premium !== undefined && typeof premium !== "boolean") {
      throw new HttpsError("invalid-argument", "premium must be boolean");
    }
    if (jw === undefined && premium === undefined) {
      throw new HttpsError("invalid-argument", "At least one of jw/premium must be provided");
    }

    // Authorize: platform admin OR tenant owner/admin.
    let isPlatformAdmin = false;
    try {
      const platform = await db
        .collection("platform")
        .doc("platform")
        .collection("members")
        .doc(callerUid)
        .get();
      isPlatformAdmin = platform.exists;
    } catch (_) {}

    if (!isPlatformAdmin) {
      const callerMember = await db
        .collection("tenants")
        .doc(tenantId)
        .collection("members")
        .doc(callerUid)
        .get();
      const callerRole = (callerMember.data()?.role ?? "").toString().trim().toLowerCase();
      if (!(callerRole === "owner" || callerRole === "admin")) {
        throw new HttpsError("permission-denied", "Caller is not tenant admin");
      }
    }

    const memberRef = db.collection("tenants").doc(tenantId).collection("members").doc(targetUid);
    const userTenantsRef = db.collection("userTenants").doc(targetUid);
    const entRef = db.collection("users").doc(targetUid).collection("entitlements").doc(tenantId);

    const now = Date.now();

    await db.runTransaction(async (tx) => {
      const memberSnap = await tx.get(memberRef);
      const memberData = memberSnap.exists ? (memberSnap.data() || {}) : {};
      const existingRole = (memberData.role ?? "viewer").toString().trim().toLowerCase() || "viewer";
      const existingStatus = (memberData.status ?? "active").toString().trim().toLowerCase() || "active";
      const createdAt =
        memberSnap.exists && memberData.createdAt ? memberData.createdAt : FieldValue.serverTimestamp();

      // ---- featureRoles (JW) ----
      const currentFeatureRoles = Array.isArray(memberData.featureRoles) ? memberData.featureRoles : [];
      const featureSet = new Set(currentFeatureRoles.map((r) => String(r).trim().toLowerCase()).filter(Boolean));
      if (jw !== undefined) {
        if (jw) featureSet.add("jw");
        else featureSet.delete("jw");
      }
      const featureRoles = Array.from(featureSet).sort();

      // ---- entitlements (complimentary premium) ----
      const entSnap = await tx.get(entRef);
      const ent = entSnap.exists ? (entSnap.data() || {}) : {};

      const prevManualActive = ent.manualActive === true;
      const manualActive = (premium !== undefined) ? premium : prevManualActive;

      // Preserve purchase info if present (backward-compatible with existing schema).
      const purchaseActive =
        typeof ent.purchaseActive === "boolean"
          ? ent.purchaseActive
          : (ent.platform && ent.platform !== "manual" ? (ent.active === true) : (ent.active === true && ent.validUntil));
      const purchaseValidUntil =
        ent.purchaseValidUntil ?? ent.validUntil ?? null;
      const purchaseValidUntilMs = purchaseValidUntil && purchaseValidUntil.toDate
        ? purchaseValidUntil.toDate().getTime()
        : (purchaseValidUntil instanceof Date ? purchaseValidUntil.getTime() : (purchaseValidUntil ? new Date(purchaseValidUntil).getTime() : 0));
      const purchaseStillValid =
        purchaseActive === true && (purchaseValidUntilMs ? purchaseValidUntilMs > now : true);

      const effectiveActive = manualActive || purchaseStillValid;
      const effectiveValidUntil = manualActive ? null : (purchaseStillValid ? purchaseValidUntil : null);
      const purchasePlatform = ent.purchasePlatform ?? (ent.platform && ent.platform !== "manual" ? ent.platform : null);
      const purchaseSubscriptionType = ent.purchaseSubscriptionType ?? (ent.platform && ent.platform !== "manual" ? ent.subscriptionType : null);
      const purchaseProductId = ent.purchaseProductId ?? (ent.platform && ent.platform !== "manual" ? ent.productId : null);

      const platformEffective = manualActive ? "manual" : (purchasePlatform || ent.platform || null);
      const subscriptionTypeEffective = manualActive ? "complimentary" : (purchaseSubscriptionType || ent.subscriptionType || null);

      tx.set(
        entRef,
        {
          uid: targetUid,
          tenantId,
          manualActive,
          manualGrantedBy: manualActive ? callerUid : (ent.manualGrantedBy ?? null),
          manualGrantedAt: manualActive ? (ent.manualGrantedAt ?? FieldValue.serverTimestamp()) : (ent.manualGrantedAt ?? null),
          purchaseActive: purchaseStillValid,
          purchaseValidUntil: purchaseStillValid ? purchaseValidUntil : null,
          purchasePlatform,
          purchaseSubscriptionType,
          purchaseProductId,
          active: effectiveActive,
          validUntil: effectiveValidUntil,
          platform: platformEffective,
          subscriptionType: subscriptionTypeEffective,
          updatedAt: FieldValue.serverTimestamp(),
          createdAt: entSnap.exists && ent.createdAt ? ent.createdAt : FieldValue.serverTimestamp(),
        },
        { merge: true }
      );

      // Keep tenant member doc in sync for tenant admin UI.
      const billing = {
        isPremium: effectiveActive,
        isComplimentary: manualActive === true,
        subscriptionType: subscriptionTypeEffective,
        validUntil: effectiveValidUntil,
        productId: manualActive ? null : purchaseProductId,
        platform: platformEffective,
      };

      tx.set(
        memberRef,
        {
          uid: targetUid,
          role: existingRole,
          status: existingStatus,
          featureRoles,
          billing,
          updatedAt: FieldValue.serverTimestamp(),
          createdAt,
        },
        { merge: true }
      );

      tx.set(
        userTenantsRef,
        {
          tenants: {
            [tenantId]: {
              role: existingRole,
              status: existingStatus,
              featureRoles,
              premium: effectiveActive,
            },
          },
          updatedAt: FieldValue.serverTimestamp(),
        },
        { merge: true }
      );
    });

    return { success: true, tenantId, targetUid };
  }
);

/**
 * Callable: updateTenantMemberProfile
 *
 * Purpose:
 * - Tenant admins/owners can edit key member profile fields (displayName/country/hearingStatus)
 * - Updates BOTH:
 *   - users/{uid} (global user profile, Admin SDK)
 *   - tenants/{tenantId}/members/{uid}.profile (denormalized for tenant admin panel)
 *
 * Note: clients cannot update other users' /users docs via Firestore rules, so this must be server-side.
 */
exports.updateTenantMemberProfile = onCall(
  {
    region: "us-central1",
    cors: true,
  },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "User must be authenticated");
    }

    const callerUid = request.auth.uid;
    const tenantId = (request.data?.tenantId ?? "").toString().trim();
    const targetUid = (request.data?.targetUid ?? "").toString().trim();
    const displayName = (request.data?.displayName ?? "").toString().trim();
    const country = (request.data?.country ?? "").toString().trim();
    const hearingStatus = (request.data?.hearingStatus ?? "").toString().trim();

    if (!tenantId) throw new HttpsError("invalid-argument", "tenantId is required");
    if (!targetUid) throw new HttpsError("invalid-argument", "targetUid is required");
    if (!displayName) throw new HttpsError("invalid-argument", "displayName is required");

    // Authorize: platform admin OR tenant owner/admin.
    let isPlatformAdmin = false;
    try {
      const platform = await db
        .collection("platform")
        .doc("platform")
        .collection("members")
        .doc(callerUid)
        .get();
      isPlatformAdmin = platform.exists;
    } catch (_) {}

    if (!isPlatformAdmin) {
      const callerMember = await db
        .collection("tenants")
        .doc(tenantId)
        .collection("members")
        .doc(callerUid)
        .get();
      const callerRole = (callerMember.data()?.role ?? "").toString().trim().toLowerCase();
      if (!(callerRole === "owner" || callerRole === "admin")) {
        throw new HttpsError("permission-denied", "Caller is not tenant admin");
      }
    }

    // Best-effort read from Auth for email/provider.
    let authUser = null;
    try {
      authUser = await auth.getUser(targetUid);
    } catch (_) {}

    const providers = authUser && Array.isArray(authUser.providerData)
      ? authUser.providerData.map((p) => String(p.providerId || "").trim()).filter(Boolean)
      : [];
    const signInProvider = providers.includes("google.com") ? "google.com" : (providers[0] || null);
    const email = authUser?.email || null;

    // Update Firebase Auth displayName (best-effort).
    try {
      await auth.updateUser(targetUid, { displayName });
    } catch (_) {
      // ignore
    }

    // Update global user profile.
    const userRef = await findUserDocRefByUid(targetUid);
    await userRef.set(
      {
        uid: targetUid,
        displayName,
        // Store both canonical and legacy fields for backward compatibility in the app.
        country,
        countryCode: country,
        userType: hearingStatus,
        hearingStatus,
        updatedAt: FieldValue.serverTimestamp(),
      },
      { merge: true }
    );

    // Update tenant member denormalized profile.
    const memberRef = db.collection("tenants").doc(tenantId).collection("members").doc(targetUid);
    await memberRef.set(
      {
        uid: targetUid,
        profile: {
          displayName,
          email,
          signInProvider,
          countryCode: country,
          hearingStatus,
          // Keep legacy aliases for older UI readers.
          country,
          userType: hearingStatus,
        },
        updatedAt: FieldValue.serverTimestamp(),
      },
      { merge: true }
    );

    return {
      success: true,
      tenantId,
      targetUid,
      profile: { displayName, country, hearingStatus, signInProvider },
    };
  }
);

/**
 * Callable: refreshTenantMemberProfileFromAuth
 *
 * Purpose:
 * - Tenant admins/owners can force-refresh a member's denormalized tenant profile from:
 *   - Firebase Auth (email, displayName, provider)
 *   - users/{uid} (country/hearing fields)
 *   - users/{uid}/entitlements/{tenantId} (billing premium flags)
 *
 * This does NOT change tenant role/status. It only updates the member doc's
 * profile/billing to keep the admin UI accurate.
 */
exports.refreshTenantMemberProfileFromAuth = onCall(
  {
    region: "us-central1",
    cors: true,
  },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "User must be authenticated");
    }

    const callerUid = request.auth.uid;
    const tenantId = (request.data?.tenantId ?? "").toString().trim();
    const targetUid = (request.data?.targetUid ?? "").toString().trim();

    if (!tenantId) throw new HttpsError("invalid-argument", "tenantId is required");
    if (!targetUid) throw new HttpsError("invalid-argument", "targetUid is required");

    // Authorize: platform admin OR tenant owner/admin.
    let isPlatformAdmin = false;
    try {
      const platform = await db
        .collection("platform")
        .doc("platform")
        .collection("members")
        .doc(callerUid)
        .get();
      isPlatformAdmin = platform.exists;
    } catch (_) {}

    if (!isPlatformAdmin) {
      const callerMember = await db
        .collection("tenants")
        .doc(tenantId)
        .collection("members")
        .doc(callerUid)
        .get();
      const callerRole = (callerMember.data()?.role ?? "").toString().trim().toLowerCase();
      if (!(callerRole === "owner" || callerRole === "admin")) {
        throw new HttpsError("permission-denied", "Caller is not tenant admin");
      }
    }

    // Read Firebase Auth user.
    let authUser = null;
    try {
      authUser = await auth.getUser(targetUid);
    } catch (e) {
      throw new HttpsError("not-found", `Auth user not found: ${e?.message || e}`);
    }

    const providers = Array.isArray(authUser.providerData)
      ? authUser.providerData.map((p) => String(p.providerId || "").trim()).filter(Boolean)
      : [];
    const signInProvider = providers.includes("google.com") ? "google.com" : (providers[0] || null);
    const email = authUser.email || null;
    const displayName = authUser.displayName || null;

    // Read global user doc for country/hearing fields.
    let country = null;
    let hearingStatus = null;
    try {
      const userRef = await findUserDocRefByUid(targetUid);
      const snap = await userRef.get();
      const u = snap.exists ? snap.data() || {} : {};
      country = u.countryCode ?? u.country ?? u.country_code ?? null;
      hearingStatus = u.hearingStatus ?? u.hearing_status ?? u.userType ?? null;
    } catch (_) {}

    // Read entitlement for billing.
    let billing = {};
    try {
      const entSnap = await db.collection("users").doc(targetUid).collection("entitlements").doc(tenantId).get();
      const ent = entSnap.exists ? entSnap.data() || {} : {};
      const isComplimentary = ent.manualActive === true || ent.platform === "manual" || ent.subscriptionType === "complimentary";
      billing = {
        isPremium: ent.active === true,
        isComplimentary,
        subscriptionType: ent.subscriptionType || null,
        validUntil: ent.validUntil || null,
        productId: ent.productId || null,
        platform: ent.platform || null,
      };
    } catch (_) {
      // ignore
    }

    const memberRef = db.collection("tenants").doc(tenantId).collection("members").doc(targetUid);
    await memberRef.set(
      {
        uid: targetUid,
        profile: {
          displayName,
          email,
          signInProvider,
          countryCode: country,
          hearingStatus,
          // legacy aliases
          country,
          userType: hearingStatus,
        },
        billing,
        updatedAt: FieldValue.serverTimestamp(),
      },
      { merge: true }
    );

    return {
      success: true,
      tenantId,
      targetUid,
      profile: { displayName, email, signInProvider, country, hearingStatus },
      billing,
    };
  }
);

/**
 * Callable: reconcileSubscriptionRoles
 *
 * Why this exists:
 * - Play cancellations are end-of-period; users should retain access until expiry.
 * - When the period ends, we need to downgrade roles (paidUser -> freeUser).
 * - This runs on app startup/login to keep roles consistent without needing RTDN.
 */
exports.reconcileSubscriptionRoles = onCall(
  {
    region: "us-central1",
    cors: true,
  },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "User must be authenticated");
    }

    const uid = request.auth.uid;
    const userRef = await findUserDocRefByUid(uid);
    const snap = await userRef.get();
    if (!snap.exists) {
      throw new HttpsError("not-found", "User document not found");
    }

    const data = snap.data() || {};
    const currentRoles = Array.isArray(data?.roles) ? data.roles : [];
    const rolesSet = new Set(currentRoles.map((r) => String(r)));

    const subscriptionActiveFlag = Boolean(data.subscription_active);
    const renewalDate = data.subscription_renewal_date
      ? new Date(data.subscription_renewal_date.toDate ? data.subscription_renewal_date.toDate() : data.subscription_renewal_date)
      : null;

    const now = Date.now();
    const renewalMs = renewalDate ? renewalDate.getTime() : 0;
    const isStillActive = subscriptionActiveFlag && renewalMs > now;

    if (isStillActive) {
      rolesSet.add("paidUser");
    } else {
      rolesSet.delete("paidUser");
    }

    const newRoles = normalizeRoles(Array.from(rolesSet));

    const update = {
      roles: newRoles,
      updatedAt: FieldValue.serverTimestamp(),
    };

    // If the subscription is not active anymore, mark it inactive server-side.
    if (!isStillActive && subscriptionActiveFlag) {
      update.subscription_active = false;
    }

    await userRef.set(update, { merge: true });
    await setUserRolesInAuth(uid, newRoles);

    return {
      success: true,
      active: isStillActive,
      renewalDate: renewalDate ? renewalDate.toISOString() : null,
      roles: newRoles,
    };
  }
);

/**
 * Admin-only callable: backfillWordLowerFields
 * Populates english_lower / bengali_lower for existing word documents.
 *
 * Note: Firestore cannot query for missing fields directly; this runs on a batch
 * of documents and only updates those missing or mismatching lower fields.
 */
exports.backfillWordLowerFields = onCall(
  {
    region: "us-central1",
    cors: true,
  },
  async (request) => {
    function asString(v) {
      return (v ?? "").toString();
    }
    function listOfStrings(v) {
      if (!Array.isArray(v)) return [];
      return v.map((x) => asString(x).trim()).filter(Boolean);
    }
    function mergeMap(existing, next) {
      const out = { ...(existing && typeof existing === "object" ? existing : {}) };
      for (const [k, v] of Object.entries(next || {})) {
        if (v == null) continue;
        if (typeof v === "string" && !v.trim()) continue;
        out[k] = v;
      }
      return out;
    }
    function mergeListMap(existing, next) {
      const out = { ...(existing && typeof existing === "object" ? existing : {}) };
      for (const [k, v] of Object.entries(next || {})) {
        const list = Array.isArray(v) ? v : [];
        const merged = Array.from(new Set([...(Array.isArray(out[k]) ? out[k] : []), ...list]))
          .map((x) => asString(x).trim())
          .filter(Boolean);
        if (merged.length) out[k] = merged;
      }
      return out;
    }

    if (!request.auth) {
      throw new HttpsError("unauthenticated", "User must be authenticated");
    }

    const callerUid = request.auth.uid;
    let callerRoles = [];
    try {
      const callerUser = await auth.getUser(callerUid);
      callerRoles = Array.isArray(callerUser.customClaims?.roles) ? callerUser.customClaims.roles : [];
    } catch (error) {
      console.error("Error fetching caller user:", error);
      throw new HttpsError("internal", "Error verifying admin access");
    }

    if (!callerRoles.includes("admin")) {
      const callerDoc = await db.collection("users").where("uid", "==", callerUid).limit(1).get();
      if (callerDoc.empty) {
        throw new HttpsError("permission-denied", "User document not found");
      }
      const firestoreRoles = Array.isArray(callerDoc.docs[0].data().roles) ? callerDoc.docs[0].data().roles : [];
      if (!firestoreRoles.includes("admin")) {
        throw new HttpsError("permission-denied", "Only admins can run backfill");
      }
    }

    const limitRaw = request.data?.limit;
    const limitNum = typeof limitRaw === "number" ? limitRaw : Number(limitRaw);
    const limit = Number.isFinite(limitNum) ? Math.max(1, Math.min(2000, limitNum)) : 500;

    const tenantId = request.data?.tenantId;
    if (!tenantId || typeof tenantId !== "string") {
      throw new HttpsError("invalid-argument", "tenantId is required");
    }

    const wordsRef = db.collection("tenants").doc(tenantId).collection("concepts");
    const startAfterDocId = request.data?.startAfterDocId;
    let q = wordsRef.orderBy(FieldPath.documentId()).limit(limit);
    if (typeof startAfterDocId === "string" && startAfterDocId.trim()) {
      q = q.startAfter(startAfterDocId.trim());
    }
    const snap = await q.get();

    let scanned = 0;
    let updated = 0;

    const batch = db.batch();

    for (const doc of snap.docs) {
      scanned++;
      const data = doc.data() || {};
      const english = typeof data.english === "string" ? data.english : "";
      const bengali = typeof data.bengali === "string" ? data.bengali : "";
      const nextEnglishLower = english.trim().toLowerCase();
      const nextBengaliLower = bengali.trim().toLowerCase();

      const curEnglishLower = typeof data.english_lower === "string" ? data.english_lower : null;
      const curBengaliLower = typeof data.bengali_lower === "string" ? data.bengali_lower : null;

      const patch = {};
      if (curEnglishLower !== nextEnglishLower) patch.english_lower = nextEnglishLower;
      if (curBengaliLower !== nextBengaliLower) patch.bengali_lower = nextBengaliLower;

      // Backfill multi-language schema (labels/labels_lower/synonyms/antonyms) from legacy EN/BN fields.
      const existingLabels = data.labels || {};
      const nextLabels = {};
      if (english.trim()) nextLabels.en = english.trim();
      if (bengali.trim()) nextLabels.bn = bengali.trim();
      const mergedLabels = mergeMap(existingLabels, nextLabels);
      const labelsChanged =
        (english.trim() && asString(existingLabels.en).trim() !== english.trim()) ||
        (bengali.trim() && asString(existingLabels.bn).trim() !== bengali.trim());

      const existingLabelsLower = data.labels_lower || {};
      const nextLabelsLower = {};
      if (english.trim()) nextLabelsLower.en = (asString(data.english_lower).trim() || nextEnglishLower);
      if (bengali.trim()) nextLabelsLower.bn = (asString(data.bengali_lower).trim() || nextBengaliLower);
      const mergedLabelsLower = mergeMap(existingLabelsLower, nextLabelsLower);
      const labelsLowerChanged =
        (english.trim() && asString(existingLabelsLower.en).trim() !== asString(nextLabelsLower.en).trim()) ||
        (bengali.trim() && asString(existingLabelsLower.bn).trim() !== asString(nextLabelsLower.bn).trim());

      const nextSynonyms = {
        en: listOfStrings(data.englishWordSynonyms),
        bn: listOfStrings(data.bengaliWordSynonyms),
      };
      const nextAntonyms = {
        en: listOfStrings(data.englishWordAntonyms),
        bn: listOfStrings(data.bengaliWordAntonyms),
      };

      const mergedSynonyms = mergeListMap(data.synonyms, nextSynonyms);
      const mergedAntonyms = mergeListMap(data.antonyms, nextAntonyms);

      // Only write maps when they actually change (avoid noisy writes).
      if (labelsChanged && Object.keys(mergedLabels).length) patch.labels = mergedLabels;
      if (labelsLowerChanged && Object.keys(mergedLabelsLower).length) patch.labels_lower = mergedLabelsLower;
      if ((nextSynonyms.en && nextSynonyms.en.length) || (nextSynonyms.bn && nextSynonyms.bn.length)) {
        // Compare merged size to current size as a cheap change signal.
        const curSyn = data.synonyms && typeof data.synonyms === "object" ? data.synonyms : {};
        if (JSON.stringify(mergedSynonyms) !== JSON.stringify(curSyn)) patch.synonyms = mergedSynonyms;
      }
      if ((nextAntonyms.en && nextAntonyms.en.length) || (nextAntonyms.bn && nextAntonyms.bn.length)) {
        const curAnt = data.antonyms && typeof data.antonyms === "object" ? data.antonyms : {};
        if (JSON.stringify(mergedAntonyms) !== JSON.stringify(curAnt)) patch.antonyms = mergedAntonyms;
      }

      const anyTextMapChanged = labelsChanged || labelsLowerChanged || patch.synonyms || patch.antonyms;
      if (anyTextMapChanged) {
        patch.migrations = mergeMap(data.migrations, {
          labelsV1At: FieldValue.serverTimestamp(),
          labelsV1By: "cf:backfillWordLowerFields",
        });
      }

      if (Object.keys(patch).length > 0) {
        batch.update(doc.ref, patch);
        updated++;
      }
    }

    if (updated > 0) {
      await batch.commit();
    }

    const last = snap.docs.length > 0 ? snap.docs[snap.docs.length - 1].id : null;
    const done = snap.docs.length < limit;
    return { success: true, scanned, updated, limit, nextStartAfterDocId: last, done };
  }
);

/**
 * Admin-only callable: backfillWordVideoFields
 * Backfills new canonical video URL keys in variants:
 *   - videos_360 / videos_480 / videos_720
 * from legacy fields:
 *   - videoUrlSD / videoUrl / videoUrlHD
 */
exports.backfillWordVideoFields = onCall(
  {
    region: "us-central1",
    cors: true,
  },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "User must be authenticated");
    }

    const callerUid = request.auth.uid;
    let callerRoles = [];
    try {
      const callerUser = await auth.getUser(callerUid);
      callerRoles = Array.isArray(callerUser.customClaims?.roles) ? callerUser.customClaims.roles : [];
    } catch (error) {
      console.error("Error fetching caller user:", error);
      throw new HttpsError("internal", "Error verifying admin access");
    }

    if (!callerRoles.includes("admin")) {
      const callerDoc = await db.collection("users").where("uid", "==", callerUid).limit(1).get();
      if (callerDoc.empty) {
        throw new HttpsError("permission-denied", "User document not found");
      }
      const firestoreRoles = Array.isArray(callerDoc.docs[0].data().roles) ? callerDoc.docs[0].data().roles : [];
      if (!firestoreRoles.includes("admin")) {
        throw new HttpsError("permission-denied", "Only admins can run backfill");
      }
    }

    // Firestore write batches are limited to 500 operations.
    // Keep a safety margin so we never exceed the limit even if every doc needs an update.
    const limitRaw = request.data?.limit;
    const limitNum = typeof limitRaw === "number" ? limitRaw : Number(limitRaw);
    const limit = Number.isFinite(limitNum) ? Math.max(1, Math.min(400, limitNum)) : 400;

    const tenantId = request.data?.tenantId;
    if (!tenantId || typeof tenantId !== "string") {
      throw new HttpsError("invalid-argument", "tenantId is required");
    }

    const startAfterDocId = request.data?.startAfterDocId;
    const wordsRef = db.collection("tenants").doc(tenantId).collection("concepts");
    let q = wordsRef.orderBy(FieldPath.documentId()).limit(limit);
    if (typeof startAfterDocId === "string" && startAfterDocId.trim()) {
      q = q.startAfter(startAfterDocId.trim());
    }
    const snap = await q.get();

    let scanned = 0;
    let updated = 0;
    let inBatch = 0;
    let batch = db.batch();

    for (const doc of snap.docs) {
      scanned++;
      const data = doc.data() || {};
      const variants = Array.isArray(data.variants) ? data.variants : [];
      if (!variants.length) continue;

      let changed = false;
      const nextVariants = variants.map((raw) => {
        if (!raw || typeof raw !== "object") return raw;
        const v = { ...raw };
        const legacy480 = typeof v.videoUrl === "string" ? v.videoUrl.trim() : "";
        const legacy360 = typeof v.videoUrlSD === "string" ? v.videoUrlSD.trim() : "";
        const legacy720 = typeof v.videoUrlHD === "string" ? v.videoUrlHD.trim() : "";

        const cur480 = typeof v.videos_480 === "string" ? v.videos_480.trim() : "";
        const cur360 = typeof v.videos_360 === "string" ? v.videos_360.trim() : "";
        const cur720 = typeof v.videos_720 === "string" ? v.videos_720.trim() : "";

        if (!cur480 && legacy480) {
          v.videos_480 = legacy480;
          changed = true;
        }
        if (!cur360 && legacy360) {
          v.videos_360 = legacy360;
          changed = true;
        }
        if (!cur720 && legacy720) {
          v.videos_720 = legacy720;
          changed = true;
        }
        return v;
      });

      if (changed) {
        batch.update(doc.ref, {
          variants: nextVariants,
          migrations: {
            ...(data.migrations && typeof data.migrations === "object" ? data.migrations : {}),
            videoV1At: FieldValue.serverTimestamp(),
            videoV1By: "cf:backfillWordVideoFields",
          },
          updatedAt: FieldValue.serverTimestamp(),
        });
        updated++;
        inBatch++;
        if (inBatch >= 450) {
          await batch.commit();
          batch = db.batch();
          inBatch = 0;
        }
      }
    }

    if (inBatch > 0) {
      await batch.commit();
    }

    const last = snap.docs.length > 0 ? snap.docs[snap.docs.length - 1].id : null;
    const done = snap.docs.length < limit;
    return { success: true, scanned, updated, limit, nextStartAfterDocId: last, done };
  }
);

/**
 * Callable: deleteReplacedWordMedia
 * Deletes old media objects that were replaced, but only if they are no longer referenced
 * by the current word document (server-side verification).
 */
exports.deleteReplacedWordMedia = onCall(
  {
    region: "us-central1",
    cors: true,
  },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "User must be authenticated");
    }

    const callerUid = request.auth.uid;
    let callerRoles = [];
    try {
      const callerUser = await auth.getUser(callerUid);
      callerRoles = Array.isArray(callerUser.customClaims?.roles) ? callerUser.customClaims.roles : [];
    } catch (error) {
      console.error("Error fetching caller user:", error);
      throw new HttpsError("internal", "Error verifying access");
    }

    const hasClaim = callerRoles.includes("admin") || callerRoles.includes("editor");
    if (!hasClaim) {
      const callerDoc = await db.collection("users").where("uid", "==", callerUid).limit(1).get();
      if (callerDoc.empty) {
        throw new HttpsError("permission-denied", "User document not found");
      }
      const firestoreRoles = Array.isArray(callerDoc.docs[0].data().roles) ? callerDoc.docs[0].data().roles : [];
      const ok = firestoreRoles.includes("admin") || firestoreRoles.includes("editor");
      if (!ok) {
        throw new HttpsError("permission-denied", "Only admins or editors can delete replaced media");
      }
    }

    const tenantId = request.data?.tenantId;
    const wordId = request.data?.conceptId || request.data?.wordId;
    const oldUrls = request.data?.oldUrls;
    const signLangId = (typeof request.data?.signLangId === "string" && request.data.signLangId.trim())
      ? request.data.signLangId.trim()
      : "bdsl";
    if (!tenantId || typeof tenantId !== "string") {
      throw new HttpsError("invalid-argument", "tenantId is required");
    }
    if (!wordId || typeof wordId !== "string") {
      throw new HttpsError("invalid-argument", "conceptId is required");
    }
    if (!Array.isArray(oldUrls)) {
      throw new HttpsError("invalid-argument", "oldUrls must be an array");
    }

    const ref = db.collection("tenants").doc(tenantId).collection("concepts").doc(wordId);
    const snap = await ref.get();
    if (!snap.exists) {
      throw new HttpsError("not-found", "Word not found");
    }

    const currentData = snap.data() || {};
    const currentUrls = new Set(collectDictionaryMediaUrls(currentData));

    const bucket = storage.bucket(DEFAULT_STORAGE_BUCKET);
    const allowedPrefixes = [
      `tenants/${tenantId}/signLanguages/${signLangId}/`,
      "bangla_sign_language/dictionary_eng_bnsl/",
    ];

    const summary = {
      wordId,
      requested: oldUrls.length,
      deleted: 0,
      skippedStillReferenced: 0,
      skippedInvalid: 0,
      skippedOutsidePrefix: 0,
      skippedOtherBucket: 0,
      notFound: 0,
      deletedObjects: [],
    };

    for (const u of oldUrls.slice(0, 500)) {
      if (typeof u !== "string" || !u.trim()) {
        summary.skippedInvalid++;
        continue;
      }
      const url = u.trim();
      if (currentUrls.has(url)) {
        summary.skippedStillReferenced++;
        continue;
      }
      const parsed = tryParseStorageObjectFromUrl(url);
      if (!parsed || !parsed.objectPath || !parsed.bucket) {
        summary.skippedInvalid++;
        continue;
      }
      if (parsed.bucket !== DEFAULT_STORAGE_BUCKET) {
        summary.skippedOtherBucket++;
        continue;
      }
      const okPrefix = allowedPrefixes.some((p) => parsed.objectPath.startsWith(p));
      if (!okPrefix) {
        summary.skippedOutsidePrefix++;
        continue;
      }

      try {
        await bucket.file(parsed.objectPath).delete();
        summary.deleted++;
        summary.deletedObjects.push(parsed.objectPath);
      } catch (e) {
        const code = e?.code || e?.statusCode;
        if (code === 404) {
          summary.notFound++;
        } else {
          console.warn("deleteReplacedWordMedia: storage delete failed:", parsed.objectPath, e?.message || e);
        }
      }
    }

    return { success: true, summary };
  }
);

/**
 * Admin-only callable: deleteDictionaryEntry
 * Deletes a dictionary word document and all referenced media in Storage.
 */
exports.deleteDictionaryEntry = onCall(
  {
    region: "us-central1",
    cors: true,
  },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "User must be authenticated");
    }

    const callerUid = request.auth.uid;
    let callerRoles = [];
    try {
      const callerUser = await auth.getUser(callerUid);
      callerRoles = Array.isArray(callerUser.customClaims?.roles) ? callerUser.customClaims.roles : [];
    } catch (error) {
      console.error("Error fetching caller user:", error);
      throw new HttpsError("internal", "Error verifying admin access");
    }

    if (!callerRoles.includes("admin")) {
      const callerDoc = await db.collection("users").where("uid", "==", callerUid).limit(1).get();
      if (callerDoc.empty) {
        throw new HttpsError("permission-denied", "User document not found");
      }
      const firestoreRoles = Array.isArray(callerDoc.docs[0].data().roles) ? callerDoc.docs[0].data().roles : [];
      if (!firestoreRoles.includes("admin")) {
        throw new HttpsError("permission-denied", "Only admins can delete dictionary entries");
      }
    }

    const tenantId = request.data?.tenantId;
    const wordId = request.data?.conceptId || request.data?.wordId;
    const signLangId = (typeof request.data?.signLangId === "string" && request.data.signLangId.trim())
      ? request.data.signLangId.trim()
      : "bdsl";
    if (!tenantId || typeof tenantId !== "string") {
      throw new HttpsError("invalid-argument", "tenantId is required");
    }
    if (!wordId || typeof wordId !== "string") {
      throw new HttpsError("invalid-argument", "conceptId is required");
    }

    const ref = db.collection("tenants").doc(tenantId).collection("concepts").doc(wordId);
    const snap = await ref.get();
    if (!snap.exists) {
      throw new HttpsError("not-found", "Word not found");
    }

    const data = snap.data() || {};
    const urls = collectDictionaryMediaUrls(data);
    const uniqueUrls = Array.from(new Set(urls));

    const parsed = uniqueUrls
      .map((u) => ({ url: u, parsed: tryParseStorageObjectFromUrl(u) }))
      .filter((x) => x.parsed && x.parsed.objectPath);

    const bucket = storage.bucket(DEFAULT_STORAGE_BUCKET);
    const allowedPrefixes = [
      `tenants/${tenantId}/signLanguages/${signLangId}/`,
      "bangla_sign_language/dictionary_eng_bnsl/",
    ];

    const summary = {
      wordId,
      urlsFound: uniqueUrls.length,
      storageObjectsDeleted: 0,
      storageObjectsNotFound: 0,
      storageObjectsSkipped: 0,
      skippedUrls: [],
      deletedObjects: [],
      notFoundObjects: [],
    };

    for (const item of parsed) {
      const { bucket: b, objectPath } = item.parsed;
      // Only delete from our known bucket; never delete arbitrary buckets.
      if (b !== DEFAULT_STORAGE_BUCKET) {
        summary.storageObjectsSkipped++;
        summary.skippedUrls.push(item.url);
        continue;
      }
      const okPrefix = allowedPrefixes.some((p) => objectPath.startsWith(p));
      if (!okPrefix) {
        summary.storageObjectsSkipped++;
        summary.skippedUrls.push(item.url);
        continue;
      }

      try {
        await bucket.file(objectPath).delete();
        summary.storageObjectsDeleted++;
        summary.deletedObjects.push(objectPath);
      } catch (e) {
        // Ignore missing objects (idempotent deletes)
        const code = e?.code || e?.statusCode;
        if (code === 404) {
          summary.storageObjectsNotFound++;
          summary.notFoundObjects.push(objectPath);
        } else {
          console.warn("Storage delete failed:", objectPath, e?.message || e);
          // Continue; we still attempt to delete the Firestore doc to avoid dangling entries.
        }
      }
    }

    await ref.delete();

    return { success: true, summary };
  }
);

exports.deleteUserAndData = onCall(
  {
    region: "us-central1",
    cors: true,
  },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "User must be authenticated");
    }

    const callerUid = request.auth.uid;
    let callerRoles = [];
    try {
      const callerUser = await auth.getUser(callerUid);
      callerRoles = Array.isArray(callerUser.customClaims?.roles) ? callerUser.customClaims.roles : [];
    } catch (error) {
      console.error("Error fetching caller user:", error);
      throw new HttpsError("internal", "Error verifying admin access");
    }

    if (!callerRoles.includes("admin")) {
      const callerDoc = await db.collection("users").where("uid", "==", callerUid).limit(1).get();
      if (callerDoc.empty) {
        throw new HttpsError("permission-denied", "User document not found");
      }
      const firestoreRoles = Array.isArray(callerDoc.docs[0].data().roles) ? callerDoc.docs[0].data().roles : [];
      if (!firestoreRoles.includes("admin")) {
        throw new HttpsError("permission-denied", "Only admins can delete users");
      }
    }

    const { userId } = request.data;
    if (!userId || typeof userId !== "string") {
      throw new HttpsError("invalid-argument", "userId is required");
    }

    const summary = {
      profileDocsDeleted: 0,
      counterDocsDeleted: 0,
      roleLogsDeleted: 0,
      customCollectionsDeleted: {},
    };

    const profileDocs = await db.collection("users").where("uid", "==", userId).get();
    for (const doc of profileDocs.docs) {
      await deleteDocumentRecursive(doc.ref);
      summary.profileDocsDeleted++;
    }

    const directDocRef = db.collection("users").doc(userId);
    const directDoc = await directDocRef.get();
    if (directDoc.exists) {
      await deleteDocumentRecursive(directDocRef);
      summary.profileDocsDeleted++;
    }

    const countersRef = db.collection("user_counters").doc(userId);
    if ((await countersRef.get()).exists) {
      await deleteDocumentRecursive(countersRef);
      summary.counterDocsDeleted++;
    }

    const perUserCollections = [
      { name: "favorites", field: "userId" },
      { name: "quizHistory", field: "userId" },
      { name: "reminders", field: "userId" },
      { name: "reviewLists", field: "userId" },
      { name: "sessionCounters", field: "userId" },
    ];

    for (const collection of perUserCollections) {
      try {
        const snapshot = await db.collection(collection.name).where(collection.field, "==", userId).get();
        if (!snapshot.empty) {
          for (const doc of snapshot.docs) {
            await deleteDocumentRecursive(doc.ref);
          }
          summary.customCollectionsDeleted[collection.name] = snapshot.size;
        }
      } catch (error) {
        console.warn(`Warning while cleaning ${collection.name}:`, error.message);
      }
    }

    const roleLogsSnap = await db.collection("roleLogs").where("userId", "==", userId).get();
    for (const log of roleLogsSnap.docs) {
      await log.ref.delete();
      summary.roleLogsDeleted++;
    }

    try {
      await auth.deleteUser(userId);
    } catch (error) {
      if (error.code !== "auth/user-not-found") {
        console.error("Error deleting auth user:", error);
        throw new HttpsError("internal", `Failed to delete auth user: ${error.message}`);
      }
    }

    return { success: true, summary };
  }
);

/**
 * Send approval email to user using SendGrid
 * Requires SENDGRID_API_KEY environment variable
 */
async function sendApprovalEmail(userId, email, displayName, roles, country) {
  // Check if SendGrid is configured
  const sendGridApiKey = process.env.SENDGRID_API_KEY;
  if (!sendGridApiKey) {
    console.log('SENDGRID_API_KEY not configured, skipping email');
    return;
  }

  const https = require('https');
  const roleText = roles.length > 0 ? roles.join(', ') : 'student';
  const countryText = country ? `\nCountry registered: ${country}` : '';

  const emailData = {
    personalizations: [{
      to: [{ email: email, name: displayName || email }],
      subject: 'Your Love2Learn Sign Account Has Been Approved'
    }],
    from: {
      email: process.env.SENDGRID_FROM_EMAIL || 'noreply@lovetolearnsign.app',
      name: 'Love2Learn Sign'
    },
    content: [{
      type: 'text/plain',
      value: `Welcome to Love2Learn Sign!\n\n` +
        `Your account has been approved and you have been assigned the role of ${roleText}.${countryText}\n\n` +
        `You may now sign in to access all features.\n\n` +
        `Thank you for joining us!`
    }]
  };

  const postData = JSON.stringify(emailData);

  const options = {
    hostname: 'api.sendgrid.com',
    port: 443,
    path: '/v3/mail/send',
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${sendGridApiKey}`,
      'Content-Type': 'application/json',
      'Content-Length': postData.length
    }
  };

  return new Promise((resolve, reject) => {
    const req = https.request(options, (res) => {
      let data = '';
      res.on('data', (chunk) => { data += chunk; });
      res.on('end', () => {
        if (res.statusCode >= 200 && res.statusCode < 300) {
          resolve(data);
        } else {
          reject(new Error(`SendGrid API error: ${res.statusCode} - ${data}`));
        }
      });
    });

    req.on('error', (error) => {
      reject(error);
    });

    req.write(postData);
    req.end();
  });
}

/**
 * Cloud Function: sendUserRoleNotification
 * HTTPS Callable function to send email notification to user about their roles
 * Called by admin when clicking "Notify User" button
 */
exports.sendUserRoleNotification = onCall(
  {
    region: "us-central1",
  },
  async (request) => {
    // Verify user is authenticated
    if (!request.auth) {
      throw new HttpsError('unauthenticated', 'User must be authenticated');
    }

    const callerUid = request.auth.uid;

    // Verify caller is admin
    try {
      const callerUser = await auth.getUser(callerUid);
      const callerRoles = callerUser.customClaims?.roles || [];
      if (!callerRoles.includes('admin')) {
        throw new HttpsError('permission-denied', 'Only admins can send notifications');
      }
    } catch (error) {
      if (error instanceof HttpsError) {
        throw error;
      }
      throw new HttpsError('internal', 'Error verifying admin access');
    }

    // Get parameters from request
    const { userId, email, displayName, roles, country } = request.data;

    if (!userId || !email) {
      throw new HttpsError('invalid-argument', 'userId and email are required');
    }

    const roleArray = Array.isArray(roles) ? roles : [];
    const roleText = roleArray.length > 0 ? roleArray.join(', ') : 'student';

    try {
      await sendApprovalEmail(userId, email, displayName || email, roleArray, country);
      console.log(`Role notification email sent to ${email} for user ${userId}`);
      return { success: true, message: 'Email sent successfully' };
    } catch (error) {
      console.error(`Error sending notification email:`, error);
      throw new HttpsError('internal', `Failed to send email: ${error.message}`);
    }
  }
);

/**
 * Cloud Function: validateAdminAccess
 * Callable function to validate if a user has admin role
 */
exports.validateAdminAccess = onRequest(
  {
    cors: true,
  },
  async (req, res) => {
    // Check if user is authenticated (requires Firebase Auth token in header)
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      res.status(401).json({ error: 'User must be authenticated' });
      return;
    }

    const token = authHeader.split('Bearer ')[1];
    let decodedToken;
    try {
      decodedToken = await auth.verifyIdToken(token);
    } catch (error) {
      res.status(401).json({ error: 'Invalid token' });
      return;
    }

    const uid = decodedToken.uid;

    try {
      // Get user's Custom Claims
      const user = await auth.getUser(uid);
      const roles = user.customClaims?.roles || [];

      const isAdmin = roles.includes('admin');

      res.json({
        isAdmin: isAdmin,
        roles: roles,
      });
    } catch (error) {
      console.error('Error validating admin access:', error);
      res.status(500).json({ error: 'Error validating admin access' });
    }
  }
);

/**
 * SECURITY: Rate Limiting Cloud Function
 * Checks if signup attempts exceed limits (3 per hour per IP, 1 per email)
 * Returns { allowed: boolean, reason?: string }
 */
exports.checkRateLimit = onCall(
  {
    region: "us-central1",
    cors: true,
  },
  async (request) => {
    const { email, ipAddress } = request.data;

    if (!email || !ipAddress) {
      throw new HttpsError('invalid-argument', 'email and ipAddress are required');
    }

    const now = Date.now();
    const oneHourAgo = now - (60 * 60 * 1000); // 1 hour in milliseconds

    try {
      // Check IP-based rate limit (3 signups per hour)
      const ipAttemptsRef = db.collection('signupAttempts')
        .where('ipAddress', '==', ipAddress)
        .where('timestamp', '>', new Date(oneHourAgo))
        .orderBy('timestamp', 'desc');

      const ipAttempts = await ipAttemptsRef.get();

      if (ipAttempts.size >= 3) {
        return {
          allowed: false,
          reason: 'Too many signup attempts from this IP address. Please try again later.',
        };
      }

      // Check email-based rate limit (1 signup per email)
      const emailAttemptsRef = db.collection('signupAttempts')
        .where('email', '==', email.toLowerCase())
        .where('timestamp', '>', new Date(oneHourAgo));

      const emailAttempts = await emailAttemptsRef.get();

      if (emailAttempts.size >= 1) {
        return {
          allowed: false,
          reason: 'An account with this email already exists or was recently created. Please sign in instead.',
        };
      }

      // Record this attempt
      await db.collection('signupAttempts').add({
        email: email.toLowerCase(),
        ipAddress: ipAddress,
        timestamp: FieldValue.serverTimestamp(),
        createdAt: new Date(),
      });

      return { allowed: true };
    } catch (error) {
      console.error('Error checking rate limit:', error);
      // On error, allow signup (fail open) but log the error
      return { allowed: true };
    }
  }
);

/**
 * SECURITY: CAPTCHA Verification Cloud Function
 * Verifies reCAPTCHA token (for web) or device fingerprint (for mobile)
 * Returns { verified: boolean, reason?: string }
 */
exports.verifyCaptcha = onCall(
  {
    region: "us-central1",
    cors: true,
  },
  async (request) => {
    const { captchaToken, deviceId } = request.data;

    // For web: verify reCAPTCHA token
    if (captchaToken) {
      const recaptchaSecretKey = process.env.RECAPTCHA_SECRET_KEY;
      if (!recaptchaSecretKey) {
        console.warn('RECAPTCHA_SECRET_KEY not configured, skipping CAPTCHA verification');
        return { verified: true }; // Fail open if not configured
      }

      try {
        const https = require('https');
        const url = `https://www.google.com/recaptcha/api/siteverify?secret=${recaptchaSecretKey}&response=${captchaToken}`;

        return new Promise((resolve, reject) => {
          https.get(url, (res) => {
            let data = '';
            res.on('data', (chunk) => { data += chunk; });
            res.on('end', () => {
              try {
                const result = JSON.parse(data);
                if (result.success && result.score >= 0.5) {
                  resolve({ verified: true });
                } else {
                  resolve({
                    verified: false,
                    reason: 'CAPTCHA verification failed. Please try again.',
                  });
                }
              } catch (error) {
                console.error('Error parsing reCAPTCHA response:', error);
                resolve({ verified: true }); // Fail open on parse error
              }
            });
          }).on('error', (error) => {
            console.error('Error verifying reCAPTCHA:', error);
            resolve({ verified: true }); // Fail open on network error
          });
        });
      } catch (error) {
        console.error('Error in CAPTCHA verification:', error);
        return { verified: true }; // Fail open on error
      }
    }

    // For mobile: basic device ID check (can be enhanced with Firebase App Check)
    if (deviceId) {
      // Basic validation - in production, use Firebase App Check
      return { verified: true };
    }

    // No token provided - reject
    return {
      verified: false,
      reason: 'Security verification required. Please refresh and try again.',
    };
  }
);

/**
 * Cloud Function: approveUserAfterEmailVerification
 * Called when a user verifies their email address
 * Automatically approves the user and assigns "freeUser" role
 * Updates Firestore: approved: true, status: "approved", roles: ["freeUser"]
 * Updates Custom Claims with freeUser role
 */
exports.approveUserAfterEmailVerification = onCall(
  {
    region: "us-central1",
    cors: true,
  },
  async (request) => {
    // Verify user is authenticated
    if (!request.auth) {
      throw new HttpsError('unauthenticated', 'User must be authenticated');
    }

    const uid = request.auth.uid;

    try {
      // Verify that email is actually verified
      const userRecord = await auth.getUser(uid);
      if (!userRecord.emailVerified) {
        throw new HttpsError('failed-precondition', 'Email is not verified');
      }

      // Find user document by uid field
      const usersRef = db.collection('users');
      const querySnapshot = await usersRef.where('uid', '==', uid).limit(1).get();

      if (querySnapshot.empty) {
        throw new HttpsError('not-found', 'User document not found');
      }

      const userDoc = querySnapshot.docs[0];
      const userData = userDoc.data();

      // Check if already approved (idempotent)
      if (userData.approved === true && userData.status === 'approved') {
        // Already approved, but don't add duplicate freeUser role
        const currentRoles = Array.isArray(userData.roles) ? userData.roles : [];
        const normalizedCurrent = normalizeRoles(currentRoles);
        if (JSON.stringify(normalizedCurrent.sort()) !== JSON.stringify(currentRoles.map((r) => String(r)).sort())) {
          const updatedRoles = normalizedCurrent;
          await userDoc.ref.update({
            roles: updatedRoles,
            updatedAt: FieldValue.serverTimestamp(),
          });

          // Update Custom Claims
          await auth.setCustomUserClaims(uid, {
            roles: updatedRoles,
          });
        }
        return { success: true, message: 'User already approved' };
      }

      // Update Firestore: approve user and assign freeUser role
      const currentRoles = Array.isArray(userData.roles) ? userData.roles : [];
      const updatedRoles = normalizeRoles(currentRoles);

      await userDoc.ref.update({
        approved: true,
        status: 'approved',
        roles: updatedRoles,
        emailVerifiedAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
      });

      // Update Custom Claims with freeUser role
      await auth.setCustomUserClaims(uid, {
        roles: updatedRoles,
      });

      logger.info(`✅ User ${uid} automatically approved after email verification. Roles: ${updatedRoles.join(', ')}`);

      return {
        success: true,
        message: 'User approved and freeUser role assigned',
        roles: updatedRoles,
      };
    } catch (error) {
      logger.error(`❌ Error approving user ${uid} after email verification:`, error);
      if (error instanceof HttpsError) {
        throw error;
      }
      throw new HttpsError('internal', 'Failed to approve user: ' + error.message);
    }
  }
);

/**
 * Note: User registration is handled client-side in AuthService._createUserProfile()
 * This ensures users are created with roles: [], status: 'pending', approved: false
 * After email verification, approveUserAfterEmailVerification is called to approve and assign freeUser role
 */
