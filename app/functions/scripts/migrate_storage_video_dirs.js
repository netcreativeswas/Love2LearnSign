#!/usr/bin/env node
/**
 * Migrates legacy Storage prefixes to the new explicit-resolution folder names:
 *   - videos/    -> videos_480/
 *   - videos_sd/ -> videos_360/
 *   - videos_hd/ -> videos_720/
 *
 * NOTE: Firebase Storage "folders" are just prefixes. This script only migrates
 * actual objects (files). If a folder appears "empty" in the console, there may
 * be nothing to migrate.
 *
 * Usage:
 *   export GOOGLE_APPLICATION_CREDENTIALS="/path/to/serviceAccount.json"
 *   node scripts/migrate_storage_video_dirs.js --projectId <id> --tenantId <tenant> --signLangId <lang> [options]
 *
 * Options:
 *   --bucket <name>     Storage bucket name (default: <projectId>.appspot.com)
 *   --conceptId <id>   Migrate only one concept (default: all concepts)
 *   --dryRun true|false  Default: true
 *   --limit <n>        Default: 0 (no limit)
 *
 * Examples:
 *   node scripts/migrate_storage_video_dirs.js --projectId love2learnsign-1914ce --tenantId l2l-bdsl --signLangId bdsl --dryRun false
 *   node scripts/migrate_storage_video_dirs.js --projectId love2learnsign-1914ce --tenantId l2l-bdsl --signLangId bdsl --conceptId bagerhat --dryRun false
 */
const admin = require("firebase-admin");

function usageAndExit(msg) {
  if (msg) console.error(`\n[migrate_storage_video_dirs] ${msg}\n`);
  console.error(
    [
      "Usage:",
      "  node scripts/migrate_storage_video_dirs.js --projectId <id> --tenantId <tenantId> --signLangId <signLangId> [options]",
      "",
      "Required:",
      "  --projectId     Firebase project id (e.g. love2learnsign-1914ce)",
      "  --tenantId      Tenant id (e.g. l2l-bdsl)",
      "  --signLangId    Sign language id (e.g. bdsl)",
      "",
      "Optional:",
      "  --bucket        Storage bucket name (default: <projectId>.appspot.com)",
      "  --conceptId     Migrate only one concept (default: all concepts)",
      "  --dryRun        true|false (default: true)",
      "  --limit         max number of objects to migrate (default: 0 = no limit)",
      "",
      "Prereq:",
      "  GOOGLE_APPLICATION_CREDENTIALS must point to a service account JSON with Storage access.",
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

function parseBool(v, defaultValue) {
  if (v === undefined || v === null) return defaultValue;
  const s = String(v).trim().toLowerCase();
  if (s === "true" || s === "1" || s === "yes") return true;
  if (s === "false" || s === "0" || s === "no") return false;
  usageAndExit(`Invalid boolean value: ${v}`);
}

function parseIntArg(v, defaultValue) {
  if (v === undefined || v === null) return defaultValue;
  const n = Number.parseInt(String(v), 10);
  if (!Number.isFinite(n) || n < 0) usageAndExit(`Invalid integer value: ${v}`);
  return n;
}

function computeDestPath(srcPath) {
  // Order matters: handle the more specific folders first.
  if (srcPath.includes("/videos_sd/")) return srcPath.replace("/videos_sd/", "/videos_360/");
  if (srcPath.includes("/videos_hd/")) return srcPath.replace("/videos_hd/", "/videos_720/");
  if (srcPath.includes("/videos/")) return srcPath.replace("/videos/", "/videos_480/");
  return null;
}

async function main() {
  const projectId = getArg("projectId", { required: true });
  const tenantId = getArg("tenantId", { required: true });
  const signLangId = getArg("signLangId", { required: true });
  const bucketName = getArg("bucket", { required: false, defaultValue: `${projectId}.appspot.com` });
  const conceptId = getArg("conceptId", { required: false });
  const dryRun = parseBool(getArg("dryRun", { defaultValue: "true" }), true);
  const limit = parseIntArg(getArg("limit", { defaultValue: "0" }), 0);

  if (!admin.apps.length) {
    admin.initializeApp({ projectId, storageBucket: bucketName });
  }

  const bucket = admin.storage().bucket(bucketName);

  const prefixBase = `tenants/${tenantId}/signLanguages/${signLangId}/concepts/`;
  const prefix = conceptId ? `${prefixBase}${conceptId}/` : prefixBase;

  console.log(`[migrate_storage_video_dirs] projectId=${projectId}`);
  console.log(`[migrate_storage_video_dirs] bucket=${bucket.name}`);
  console.log(`[migrate_storage_video_dirs] prefix=${prefix}`);
  console.log(`[migrate_storage_video_dirs] dryRun=${dryRun} limit=${limit || "none"}`);

  let migrated = 0;
  let scanned = 0;

  let nextQuery = { prefix, autoPaginate: false, maxResults: 1000 };
  while (true) {
    const [files, , apiResponse] = await bucket.getFiles(nextQuery);
    for (const file of files) {
      scanned++;
      const src = file.name;
      const dst = computeDestPath(src);
      if (!dst) continue;
      if (dst === src) continue;

      console.log(`- ${src} -> ${dst}`);
      migrated++;

      if (!dryRun) {
        const dstFile = bucket.file(dst);
        const [exists] = await dstFile.exists();
        if (exists) {
          console.log(`  ! SKIP (dest exists): ${dst}`);
        } else {
          await file.copy(dstFile);
          await file.delete();
          console.log(`  ✓ moved`);
        }
      }

      if (limit && migrated >= limit) {
        console.log(`[migrate_storage_video_dirs] limit reached (${limit}), stopping.`);
        console.log(`[migrate_storage_video_dirs] scanned=${scanned} migrated=${migrated}`);
        return;
      }
    }

    const token = apiResponse && apiResponse.nextPageToken;
    if (!token) break;
    nextQuery = { prefix, autoPaginate: false, maxResults: 1000, pageToken: token };
  }

  console.log(`[migrate_storage_video_dirs] done. scanned=${scanned} migrated=${migrated}`);
  if (dryRun) {
    console.log(`[migrate_storage_video_dirs] dryRun=true (no changes were made). Re-run with --dryRun false to apply.`);
  }
}

main().catch((err) => {
  console.error("[migrate_storage_video_dirs] FAILED:", err);
  process.exit(1);
});


