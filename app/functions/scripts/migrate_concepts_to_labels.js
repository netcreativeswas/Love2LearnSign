#!/usr/bin/env node
/**
 * One-time migration helper:
 * - Backfills the new multi-language schema fields on `tenants/{tenantId}/concepts/*`
 *   while keeping legacy fields (english/bengali/...) for backwards compatibility.
 *
 * What it does (per concept doc):
 * - sets/merges:
 *   - labels: { en, bn? }
 *   - labels_lower: { en, bn? }
 *   - synonyms: { en: [...], bn: [...] }
 *   - antonyms: { en: [...], bn: [...] }
 * - optional: prints a report of media URLs that don't look tenant-namespaced
 *
 * Usage:
 *   export GOOGLE_APPLICATION_CREDENTIALS="/path/to/serviceAccount.json"
 *   node scripts/migrate_concepts_to_labels.js --projectId love2learnsign-1914ce --tenantId l2l-bdsl [--dryRun 1] [--limit 500]
 */

const admin = require("firebase-admin");

function usageAndExit(msg) {
  if (msg) console.error(`\n[migrate_concepts_to_labels] ${msg}\n`);
  console.error(
    [
      "Usage:",
      "  node scripts/migrate_concepts_to_labels.js --projectId <id> --tenantId <tenantId> [--dryRun 1] [--limit 500]",
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

function looksTenantNamespaced(url, tenantId) {
  const s = asString(url).trim();
  if (!s) return true;
  return s.includes(`/tenants/${tenantId}/`) || s.includes(`tenants%2F${encodeURIComponent(tenantId)}%2F`);
}

async function main() {
  const projectId = getArg("projectId", { required: true });
  const tenantId = getArg("tenantId", { required: true });
  const dryRun = getArg("dryRun", { defaultValue: "0" }) === "1";
  const limit = parseInt(getArg("limit", { defaultValue: "500" }), 10);

  if (!process.env.GOOGLE_APPLICATION_CREDENTIALS) {
    usageAndExit("GOOGLE_APPLICATION_CREDENTIALS is not set (service account JSON path).");
  }

  admin.initializeApp({
    projectId,
    credential: admin.credential.applicationDefault(),
  });

  const db = admin.firestore();
  const col = db.collection("tenants").doc(tenantId).collection("concepts");

  console.log(`[migrate_concepts_to_labels] tenantId=${tenantId} dryRun=${dryRun} limit=${limit}`);

  // We page by document name to avoid timeouts on large sets.
  let lastDoc = null;
  let updated = 0;
  let scanned = 0;
  let mediaNotNamespaced = 0;

  while (true) {
    let q = col.orderBy(admin.firestore.FieldPath.documentId()).limit(limit);
    if (lastDoc) q = q.startAfter(lastDoc);
    const snap = await q.get();
    if (snap.empty) break;

    for (const doc of snap.docs) {
      scanned++;
      lastDoc = doc;
      const data = doc.data() || {};

      const en = asString(data.english).trim();
      const bn = asString(data.bengali).trim();

      const existingLabels = data.labels || {};
      const nextLabels = {};
      if (en) nextLabels.en = en;
      if (bn) nextLabels.bn = bn;

      const existingLabelsLower = data.labels_lower || {};
      const nextLabelsLower = {};
      if (en) nextLabelsLower.en = (asString(data.english_lower).trim() || en.toLowerCase());
      if (bn) nextLabelsLower.bn = (asString(data.bengali_lower).trim() || bn.toLowerCase());

      const nextSynonyms = {
        en: listOfStrings(data.englishWordSynonyms),
        bn: listOfStrings(data.bengaliWordSynonyms),
      };
      const nextAntonyms = {
        en: listOfStrings(data.englishWordAntonyms),
        bn: listOfStrings(data.bengaliWordAntonyms),
      };

      const patch = {};
      patch.labels = mergeMap(existingLabels, nextLabels);
      patch.labels_lower = mergeMap(existingLabelsLower, nextLabelsLower);
      patch.synonyms = mergeListMap(data.synonyms, nextSynonyms);
      patch.antonyms = mergeListMap(data.antonyms, nextAntonyms);
      patch.migrations = mergeMap(data.migrations, {
        labelsV1At: admin.firestore.FieldValue.serverTimestamp(),
        labelsV1By: "script:migrate_concepts_to_labels",
      });

      // Media sanity check (variants) – only report, do not modify.
      const variants = Array.isArray(data.variants) ? data.variants : [];
      for (const v of variants) {
        if (!v || typeof v !== "object") continue;
        const urls = [v.videoUrl, v.videoUrlSD, v.videoUrlHD, v.videoThumbnail, v.videoThumbnailSmall, data.imageFlashcard];
        for (const u of urls) {
          if (!looksTenantNamespaced(u, tenantId)) {
            mediaNotNamespaced++;
            console.warn(`[migrate_concepts_to_labels] media not namespaced (concept ${doc.id}): ${u}`);
            break;
          }
        }
      }

      // Only write if there is something meaningful (avoid setting empty maps on totally empty docs).
      const hasAny =
        Object.keys(patch.labels).length ||
        Object.keys(patch.labels_lower).length ||
        Object.keys(patch.synonyms).length ||
        Object.keys(patch.antonyms).length;

      if (!hasAny) continue;

      if (!dryRun) {
        await doc.ref.set(patch, { merge: true });
      }
      updated++;
    }

    console.log(`[migrate_concepts_to_labels] progress scanned=${scanned} updated=${updated}`);
  }

  console.log(
    `[migrate_concepts_to_labels] done scanned=${scanned} updated=${updated} mediaNotNamespaced=${mediaNotNamespaced}`
  );
}

main().catch((e) => {
  console.error("[migrate_concepts_to_labels] fatal:", e);
  process.exit(1);
});


