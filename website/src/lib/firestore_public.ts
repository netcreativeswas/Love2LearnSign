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

function asVariants(v: unknown): PublicVariant[] | undefined {
  if (!Array.isArray(v)) return undefined;
  const out: PublicVariant[] = [];
  for (const item of v) {
    if (!item || typeof item !== "object") continue;
    const m = item as Record<string, unknown>;
    out.push({
      videoUrl: asString(m.videoUrl),
      videoUrlSD: asString(m.videoUrlSD),
      videoUrlHD: asString(m.videoUrlHD),
      videoThumbnail: asString(m.videoThumbnail),
      videoThumbnailSmall: asString(m.videoThumbnailSmall),
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
    asString(concept.videoUrlHD),
    asString(concept.videoUrl),
    asString(concept.videoUrlSD),
    v0 ? asString(v0.videoUrlHD) : undefined,
    v0 ? asString(v0.videoUrl) : undefined,
    v0 ? asString(v0.videoUrlSD) : undefined
  );
}

export function pickBestThumbnailUrl(concept: PublicConcept): string | undefined {
  const v0 = concept.variants?.[0];
  return pickFirst(
    asString(concept.videoThumbnail),
    asString(concept.videoThumbnailSmall),
    v0 ? asString(v0.videoThumbnail) : undefined,
    v0 ? asString(v0.videoThumbnailSmall) : undefined
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
  const baseRef = doc(db, "tenants", tenantId, "concepts", wordId);
  const signRef = doc(db, "tenants", tenantId, "concepts", wordId, "signs", signLangId);

  const [baseSnap, signSnap] = await Promise.all([getDoc(baseRef), getDoc(signRef)]);
  if (!baseSnap.exists() && !signSnap.exists()) return null;

  const base = (baseSnap.data() ?? {}) as Record<string, unknown>;
  const sign = (signSnap.data() ?? {}) as Record<string, unknown>;
  const labels = asRecord(base.labels);

  const merged: PublicConcept = {
    id: wordId,
    tenantId,
    signLangId,
    english: pickFirst(asString(base.english), labels ? asString(labels.en) : undefined),
    bengali: pickFirst(
      asString(base.bengali),
      labels ? asString(labels.bn) : undefined,
      labels ? asString(labels.bn_BD) : undefined
    ),
    categoryMain: pickFirst(asString(sign.category_main), asString(base.category_main), asString(base.categoryMain)),
    categorySub: pickFirst(asString(sign.category_sub), asString(base.category_sub), asString(base.categorySub)),
    // Merge: sign overrides base if present
    videoUrl: pickFirst(asString(sign.videoUrl), asString(base.videoUrl)),
    videoUrlSD: pickFirst(asString(sign.videoUrlSD), asString(base.videoUrlSD)),
    videoUrlHD: pickFirst(asString(sign.videoUrlHD), asString(base.videoUrlHD)),
    videoThumbnail: pickFirst(asString(sign.videoThumbnail), asString(base.videoThumbnail)),
    videoThumbnailSmall: pickFirst(asString(sign.videoThumbnailSmall), asString(base.videoThumbnailSmall)),
    variants: pickFirst(asVariants(sign.variants), asVariants(base.variants)),
  };

  return merged;
}


