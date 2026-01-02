"use client";

import Image from "next/image";
import Link from "next/link";
import { useEffect, useMemo, useState } from "react";

import { siteConfig } from "@/lib/site-config";
import { useTranslations } from "@/components/TranslationProvider";
import {
  DEFAULT_SIGN_LANG_ID,
  DEFAULT_TENANT_ID,
  fetchPublicConcept,
  pickBestThumbnailUrl,
  pickBestVideoUrl,
  type PublicConcept,
} from "@/lib/firestore_public";

export default function WordViewerClient({
  wordId,
  tenantId,
  signLangId,
}: {
  wordId: string;
  tenantId?: string;
  signLangId?: string;
}) {
  const { t } = useTranslations();
  const resolvedTenantId = tenantId?.trim() || DEFAULT_TENANT_ID;
  const resolvedSignLangId = signLangId?.trim() || DEFAULT_SIGN_LANG_ID;

  const [loading, setLoading] = useState(true);
  const [concept, setConcept] = useState<PublicConcept | null>(null);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    let cancelled = false;
    async function run() {
      setLoading(true);
      setError(null);
      try {
        const data = await fetchPublicConcept({
          wordId,
          tenantId: resolvedTenantId,
          signLangId: resolvedSignLangId,
        });
        if (cancelled) return;
        setConcept(data);
      } catch (e) {
        if (cancelled) return;
        const msg = e instanceof Error ? e.message : t("wordPage.couldNotLoadTitle");
        setError(msg);
        setConcept(null);
      } finally {
        if (!cancelled) setLoading(false);
      }
    }
    void run();
    return () => {
      cancelled = true;
    };
  }, [wordId, resolvedTenantId, resolvedSignLangId]);

  const english = useMemo(() => concept?.english?.trim() || "", [concept]);
  const bengali = useMemo(() => concept?.bengali?.trim() || "", [concept]);
  const title = useMemo(() => {
    if (english && bengali) return `${english} / ${bengali}`;
    return english || bengali || wordId;
  }, [english, bengali, wordId]);

  const videoUrl = useMemo(() => (concept ? pickBestVideoUrl(concept) : undefined), [concept]);
  const posterUrl = useMemo(() => (concept ? pickBestThumbnailUrl(concept) : undefined), [concept]);
  const categoryMain = useMemo(() => concept?.categoryMain?.trim() || "", [concept]);
  const categorySub = useMemo(() => concept?.categorySub?.trim() || "", [concept]);

  return (
    <div className="flex min-h-dvh flex-col bg-background text-foreground lg:h-dvh lg:overflow-hidden">
      {/* Minimal top bar (keep it small so the page fits one desktop screen) */}
      <header className="border-b border-border/70 bg-surface/70 backdrop-blur">
        <div className="mx-auto flex max-w-6xl items-center justify-between gap-3 px-4 py-3">
          <Link href="/" className="flex items-center gap-3 rounded-xl px-2 py-1 hover:bg-muted">
            <Image
              src="/brand/logo.png"
              alt={t("common.logoAlt", { appName: siteConfig.appName })}
              width={40}
              height={40}
              className="rounded-full object-cover"
              priority
            />
            <div className="min-w-0">
              <div className="truncate text-sm font-semibold leading-5">{t("common.appName")}</div>
              <div className="truncate text-xs text-muted-foreground">{t("wordPage.watchASign")}</div>
            </div>
          </Link>

          <a
            href={siteConfig.playStoreUrl}
            target="_blank"
            rel="noreferrer"
            className="inline-flex items-center gap-2 rounded-xl border border-border bg-surface px-3 py-2 text-sm font-semibold text-foreground/90 hover:bg-muted"
          >
            {t("wordPage.getTheApp")}
            <span aria-hidden="true">→</span>
          </a>
        </div>
      </header>

      <main className="flex-1 lg:min-h-0">
        <div className="mx-auto box-border w-full max-w-6xl px-4 py-6 lg:h-full lg:py-6">
          <div className="grid gap-6 lg:h-full lg:grid-cols-[minmax(0,1fr)_360px]">
            {/* Left: video card */}
            <section className="min-h-0">
              <div className="box-border h-full rounded-3xl border border-border bg-surface p-4 shadow-sm sm:p-6">
                <div className="flex h-full flex-col gap-3">
                  <div className="flex-none">
                    <div className="text-sm font-semibold text-muted-foreground">{t("wordPage.watchThisSign")}</div>
                    {loading ? (
                      <h1 className="mt-1 text-balance text-2xl font-semibold tracking-tight sm:text-3xl">
                        {t("wordPage.loading")}
                      </h1>
                    ) : (
                      <div className="mt-1">
                        <h1 className="text-balance text-2xl font-semibold tracking-tight sm:text-3xl">
                          {english || wordId}
                        </h1>
                        {bengali ? (
                          <div className="mt-1 text-lg font-semibold text-foreground/90 sm:text-xl">
                            {bengali}
                          </div>
                        ) : null}
                        {categoryMain ? (
                          <div className="mt-3 flex flex-wrap items-center gap-2">
                            <span className="inline-flex items-center rounded-full border border-border bg-muted px-3 py-1 text-xs font-semibold text-foreground/90">
                              {categoryMain}
                            </span>
                            {categorySub ? (
                              <span className="inline-flex items-center rounded-full border border-border bg-muted px-3 py-1 text-xs font-semibold text-foreground/90">
                                {categorySub}
                              </span>
                            ) : null}
                          </div>
                        ) : null}
                      </div>
                    )}
                  </div>

                  <div className="min-h-0 flex-1">
                    <div className="relative h-[52dvh] w-full overflow-hidden rounded-2xl bg-muted sm:h-[58dvh] lg:h-full">
                      {loading ? (
                        <div className="absolute inset-0 animate-pulse bg-muted" />
                      ) : error ? (
                        <div className="flex h-full items-center justify-center px-6 text-center">
                          <div>
                            <div className="text-sm font-semibold">{t("wordPage.couldNotLoadTitle")}</div>
                            <div className="mt-1 text-sm text-muted-foreground">{error}</div>
                          </div>
                        </div>
                      ) : !concept ? (
                        <div className="flex h-full items-center justify-center px-6 text-center">
                          <div>
                            <div className="text-sm font-semibold">{t("wordPage.wordNotFound")}</div>
                            <div className="mt-1 text-sm text-muted-foreground">
                              {t("wordPage.wordNotFoundBody")}
                            </div>
                          </div>
                        </div>
                      ) : !videoUrl ? (
                        <div className="flex h-full items-center justify-center px-6 text-center">
                          <div>
                            <div className="text-sm font-semibold">{t("wordPage.noVideo")}</div>
                            <div className="mt-1 text-sm text-muted-foreground">
                              {t("wordPage.noVideoBody")}
                            </div>
                          </div>
                        </div>
                      ) : (
                        <video
                          className="h-full w-full object-contain"
                          controls
                          playsInline
                          preload="metadata"
                          poster={posterUrl}
                        >
                          <source src={videoUrl} />
                          {t("wordPage.videoUnsupported")}
                        </video>
                      )}
                    </div>
                  </div>
                </div>
              </div>
            </section>

            {/* Right: CTA + context */}
            <aside className="lg:min-h-0">
              <div className="box-border rounded-3xl border border-border bg-surface p-4 shadow-sm sm:p-6 lg:sticky lg:top-6">
                <div className="text-sm font-semibold tracking-tight">{t("wordPage.betterExperience")}</div>
                <p className="mt-2 text-sm leading-6 text-muted-foreground">
                  {t("wordPage.installBlurb")}
                </p>

                <div className="mt-2 sm:mt-4">
                  <a
                    href={siteConfig.playStoreUrl}
                    target="_blank"
                    rel="noreferrer"
                    className="inline-flex items-center justify-center p-0 transition-opacity hover:opacity-90"
                  >
                    <Image
                      src="/icons/google-play-download.png"
                      alt={t("wordPage.getItOnGooglePlay")}
                      width={170}
                      height={56}
                      className="h-auto w-auto"
                    />
                  </a>
                </div>

                <div className="mt-2 rounded-2xl bg-muted p-3 text-sm text-muted-foreground sm:mt-4 sm:p-4">
                  {t("wordPage.sharingTip")}
                </div>
              </div>
            </aside>
          </div>
        </div>
      </main>
    </div>
  );
}


