import { doc, getDoc } from "firebase/firestore";

import { db } from "@/lib/firebase_client";

export const DEFAULT_TENANT_ID = "l2l-bdsl";
export const DEFAULT_SIGN_LANG_ID = "bdsl";

export type PublicVariant = {
  videoUrl?: string;
  videoUrlSD?: string;
  videoUrlHD?: string;
  videoThumbnail?: string;
  videoThumbnailSmall?: string;
};

export type PublicConcept = {
  id: string;
  tenantId: string;
  signLangId: string;
  english?: string;
  bengali?: string;
  categoryMain?: string;
  categorySub?: string;
  videoUrl?: string;
  videoUrlSD?: string;
  videoUrlHD?: string;
  videoThumbnail?: string;
  videoThumbnailSmall?: string;
  variants?: PublicVariant[];
};

function asString(v: unknown): string | undefined {
  return typeof v === "string" && v.trim() ? v : undefined;
}

const SAFE_PATH_SEGMENT_RE = /^[A-Za-z0-9_-]{1,200}$/;

function asSafePathSegment(v: unknown): string | undefined {
  const s = asString(v)?.trim();
  if (!s) return undefined;
  return SAFE_PATH_SEGMENT_RE.test(s) ? s : undefined;
}

function asHttpsUrl(v: unknown): string | undefined {
  const s = asString(v);
  if (!s) return undefined;
  try {
    const u = new URL(s);
    const allowHttpInDev = process.env.NODE_ENV !== "production";
    if (u.protocol !== "https:" && !(allowHttpInDev && u.protocol === "http:")) return undefined;
    return u.toString();
  } catch {
    return undefined;
  }
}

function asVariants(v: unknown): PublicVariant[] | undefined {
  if (!Array.isArray(v)) return undefined;
  const out: PublicVariant[] = [];
  for (const item of v) {
    if (!item || typeof item !== "object") continue;
    const m = item as Record<string, unknown>;
    out.push({
      videoUrl: asHttpsUrl(m.videoUrl),
      videoUrlSD: asHttpsUrl(m.videoUrlSD),
      videoUrlHD: asHttpsUrl(m.videoUrlHD),
      videoThumbnail: asHttpsUrl(m.videoThumbnail),
      videoThumbnailSmall: asHttpsUrl(m.videoThumbnailSmall),
    });
  }
  return out.length ? out : undefined;
}

function asRecord(v: unknown): Record<string, unknown> | undefined {
  if (!v || typeof v !== "object") return undefined;
  return v as Record<string, unknown>;
}

function pickFirst<T>(...vals: Array<T | undefined>): T | undefined {
  for (const v of vals) {
    if (v !== undefined) return v;
  }
  return undefined;
}

export function pickBestVideoUrl(concept: PublicConcept): string | undefined {
  const v0 = concept.variants?.[0];
  return pickFirst(
    asHttpsUrl(concept.videoUrlHD),
    asHttpsUrl(concept.videoUrl),
    asHttpsUrl(concept.videoUrlSD),
    v0 ? asHttpsUrl(v0.videoUrlHD) : undefined,
    v0 ? asHttpsUrl(v0.videoUrl) : undefined,
    v0 ? asHttpsUrl(v0.videoUrlSD) : undefined
  );
}

export function pickBestThumbnailUrl(concept: PublicConcept): string | undefined {
  const v0 = concept.variants?.[0];
  return pickFirst(
    asHttpsUrl(concept.videoThumbnail),
    asHttpsUrl(concept.videoThumbnailSmall),
    v0 ? asHttpsUrl(v0.videoThumbnail) : undefined,
    v0 ? asHttpsUrl(v0.videoThumbnailSmall) : undefined
  );
}

/**
 * Public fetch for the shared "word" landing page.
 *
 * We read:
 *  1) tenants/{tenantId}/concepts/{wordId} (labels + may contain media fields)
 *  2) tenants/{tenantId}/concepts/{wordId}/signs/{signLangId} (future-proof per-language media)
 *
 * The returned object merges sign-specific media fields over the base concept doc.
 */
export async function fetchPublicConcept({
  wordId,
  tenantId = DEFAULT_TENANT_ID,
  signLangId = DEFAULT_SIGN_LANG_ID,
}: {
  wordId: string;
  tenantId?: string;
  signLangId?: string;
}): Promise<PublicConcept | null> {
  // Hardening: prevent weird/invalid path segments coming from URL params.
  const safeWordId = asSafePathSegment(wordId);
  if (!safeWordId) return null;

  const safeTenantId = asSafePathSegment(tenantId) ?? DEFAULT_TENANT_ID;
  const safeSignLangId = asSafePathSegment(signLangId) ?? DEFAULT_SIGN_LANG_ID;

  const baseRef = doc(db, "tenants", safeTenantId, "concepts", safeWordId);
  const signRef = doc(db, "tenants", safeTenantId, "concepts", safeWordId, "signs", safeSignLangId);

  const [baseSnap, signSnap] = await Promise.all([getDoc(baseRef), getDoc(signRef)]);
  if (!baseSnap.exists() && !signSnap.exists()) return null;

  const base = (baseSnap.data() ?? {}) as Record<string, unknown>;
  const sign = (signSnap.data() ?? {}) as Record<string, unknown>;
  const labels = asRecord(base.labels);

  const merged: PublicConcept = {
    id: safeWordId,
    tenantId: safeTenantId,
    signLangId: safeSignLangId,
    english: pickFirst(asString(base.english), labels ? asString(labels.en) : undefined),
    bengali: pickFirst(
      asString(base.bengali),
      labels ? asString(labels.bn) : undefined,
      labels ? asString(labels.bn_BD) : undefined
    ),
    categoryMain: pickFirst(asString(sign.category_main), asString(base.category_main), asString(base.categoryMain)),
    categorySub: pickFirst(asString(sign.category_sub), asString(base.category_sub), asString(base.categorySub)),
    // Merge: sign overrides base if present
    videoUrl: pickFirst(asHttpsUrl(sign.videoUrl), asHttpsUrl(base.videoUrl)),
    videoUrlSD: pickFirst(asHttpsUrl(sign.videoUrlSD), asHttpsUrl(base.videoUrlSD)),
    videoUrlHD: pickFirst(asHttpsUrl(sign.videoUrlHD), asHttpsUrl(base.videoUrlHD)),
    videoThumbnail: pickFirst(asHttpsUrl(sign.videoThumbnail), asHttpsUrl(base.videoThumbnail)),
    videoThumbnailSmall: pickFirst(asHttpsUrl(sign.videoThumbnailSmall), asHttpsUrl(base.videoThumbnailSmall)),
    variants: pickFirst(asVariants(sign.variants), asVariants(base.variants)),
  };

  return merged;
}


