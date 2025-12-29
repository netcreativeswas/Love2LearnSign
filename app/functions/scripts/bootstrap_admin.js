#!/usr/bin/env node
/**
 * Bootstrap script:
 * - Creates (or fetches) a Firebase Auth user
 * - Sets Custom Claims: { roles: [...] }
 * - Seeds Firestore "bootstrap" docs needed for multi-tenant rules
 *
 * Usage:
 *   export GOOGLE_APPLICATION_CREDENTIALS="/path/to/serviceAccount.json"
 *   export BOOTSTRAP_PASSWORD='...'
 *   node scripts/bootstrap_admin.js --projectId love2learnsign-1914ce --email you@example.com \
 *     --displayName "Admin" --tenantId l2l-bdsl --appId love2learn --visibility public --tenantStatus active \
 *     --tenantRole owner --roles admin,editor,freeUser
 */

const admin = require("firebase-admin");

function usageAndExit(msg) {
  if (msg) console.error(`\n[bootstrap_admin] ${msg}\n`);
  console.error(
    [
      "Usage:",
      "  BOOTSTRAP_PASSWORD='<pw>' node scripts/bootstrap_admin.js --projectId <id> --email <email> [options]",
      "",
      "Required:",
      "  --projectId     Firebase project id (e.g. love2learnsign-1914ce)",
      "  --email         Auth user email",
      "  BOOTSTRAP_PASSWORD  Auth user password (min 6 chars)",
      "",
      "Optional:",
      "  --displayName   Display name (default: Admin)",
      "  --tenantId      Tenant id (default: l2l-bdsl)",
      "  --appId         App id (default: love2learn)",
      "  --visibility    Tenant visibility (default: public)",
      "  --tenantStatus  Tenant status (default: active)",
      "  --tenantRole    Tenant member role (default: owner)",
      "  --roles         Custom claim roles CSV (default: admin,editor,freeUser)",
      "",
      "Prereq:",
      "  GOOGLE_APPLICATION_CREDENTIALS must point to a service account JSON with access to the project.",
    ].join("\n")
  );
  process.exit(1);
}

function getArg(name, { required = false, defaultValue = undefined } = {}) {
  const idx = process.argv.indexOf(`--${name}`);
  if (idx === -1) {
    if (required) usageAndExit(`Missing --${name}`);
    return defaultValue;
  }
  const value = process.argv[idx + 1];
  if (!value || value.startsWith("--")) usageAndExit(`Missing value for --${name}`);
  return value;
}

function csvToList(s) {
  return String(s || "")
    .split(",")
    .map((x) => x.trim())
    .filter(Boolean);
}

async function main() {
  const projectId = getArg("projectId", { required: true });
  const email = getArg("email", { required: true });
  const password = process.env.BOOTSTRAP_PASSWORD;

  const displayName = getArg("displayName", { defaultValue: "Admin" });
  const tenantId = getArg("tenantId", { defaultValue: "l2l-bdsl" });
  const appId = getArg("appId", { defaultValue: "love2learn" });
  const visibility = getArg("visibility", { defaultValue: "public" });
  const tenantStatus = getArg("tenantStatus", { defaultValue: "active" });
  const tenantRole = getArg("tenantRole", { defaultValue: "owner" });
  const roles = csvToList(getArg("roles", { defaultValue: "admin,editor,freeUser" }));

  if (!process.env.GOOGLE_APPLICATION_CREDENTIALS) {
    usageAndExit("GOOGLE_APPLICATION_CREDENTIALS is not set (service account JSON path).");
  }

  // Admin SDK init (uses GOOGLE_APPLICATION_CREDENTIALS)
  admin.initializeApp({
    projectId,
    credential: admin.credential.applicationDefault(),
  });
  const auth = admin.auth();
  const db = admin.firestore();

  // 1) Create/fetch user
  let user;
  try {
    user = await auth.getUserByEmail(email);
    console.log(`[bootstrap_admin] Found existing Auth user: ${user.uid} (${email})`);
  } catch (e) {
    if (!password) usageAndExit("Missing BOOTSTRAP_PASSWORD env var (Auth password).");
    user = await auth.createUser({
      email,
      password,
      displayName,
      emailVerified: true,
      disabled: false,
    });
    console.log(`[bootstrap_admin] Created Auth user: ${user.uid} (${email})`);
  }

  // 2) Set custom claims roles
  await auth.setCustomUserClaims(user.uid, { roles });
  console.log(`[bootstrap_admin] Set custom claims roles for ${user.uid}: ${JSON.stringify(roles)}`);

  // 3) Seed Firestore docs
  const now = admin.firestore.FieldValue.serverTimestamp();

  // apps/{appId}
  await db
    .collection("apps")
    .doc(appId)
    .set(
      {
        status: "active",
        updatedAt: now,
        createdAt: now,
      },
      { merge: true }
    );

  // tenants/{tenantId}
  await db
    .collection("tenants")
    .doc(tenantId)
    .set(
      {
        visibility,
        status: tenantStatus,
        updatedAt: now,
        createdAt: now,
      },
      { merge: true }
    );

  // platform/platform/members/{uid}  (exists() => platform admin in rules)
  await db
    .collection("platform")
    .doc("platform")
    .collection("members")
    .doc(user.uid)
    .set(
      {
        uid: user.uid,
        email,
        displayName,
        roles,
        updatedAt: now,
        createdAt: now,
      },
      { merge: true }
    );

  // tenants/{tenantId}/members/{uid}
  await db
    .collection("tenants")
    .doc(tenantId)
    .collection("members")
    .doc(user.uid)
    .set(
      {
        uid: user.uid,
        email,
        role: tenantRole,
        updatedAt: now,
        createdAt: now,
      },
      { merge: true }
    );

  // users/{uid} (handy for dashboards and role sync logic)
  await db
    .collection("users")
    .doc(user.uid)
    .set(
      {
        uid: user.uid,
        email,
        displayName,
        roles,
        updatedAt: now,
        createdAt: now,
        approved: true,
        status: "active",
      },
      { merge: true }
    );

  console.log("\n[bootstrap_admin] Done.");
  console.log("Created/updated docs:");
  console.log(`- apps/${appId}`);
  console.log(`- tenants/${tenantId}`);
  console.log(`- platform/platform/members/${user.uid}`);
  console.log(`- tenants/${tenantId}/members/${user.uid}`);
  console.log(`- users/${user.uid}`);
}

main().catch((err) => {
  console.error("\n[bootstrap_admin] FAILED");
  console.error(err);
  process.exit(1);
});


