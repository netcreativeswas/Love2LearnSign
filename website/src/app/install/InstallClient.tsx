"use client";

import { useMemo, useState } from "react";
import { useSearchParams } from "next/navigation";

import { siteConfig } from "@/lib/site-config";
import { useTranslations } from "@/components/TranslationProvider";

function buildInstallUrl(params: URLSearchParams) {
  const url = new URL(`${siteConfig.url}/install`);
  const tenant = params.get("tenant") ?? params.get("tenantId");
  const app = params.get("app") ?? params.get("appId");
  const ui = params.get("ui") ?? params.get("locale");

  if (tenant) url.searchParams.set("tenant", tenant);
  if (app) url.searchParams.set("app", app);
  if (ui) url.searchParams.set("ui", ui);

  return url.toString();
}

function buildQrUrl(dataUrl: string) {
  // External QR generator (simple; no extra deps). If you prefer self-hosted QR,
  // swap this for a local generator later.
  const base = "https://api.qrserver.com/v1/create-qr-code/";
  const qs = new URLSearchParams({ size: "240x240", data: dataUrl });
  return `${base}?${qs.toString()}`;
}

function buildAndroidIntentUrl(httpsUrl: string) {
  // Android intent fallback (requires app links / correct package).
  // Example: intent://love2learnsign.com/install?...#Intent;scheme=https;package=com...;end
  const u = new URL(httpsUrl);
  const pathAndQuery = `${u.host}${u.pathname}${u.search}`;
  return `intent://${pathAndQuery}#Intent;scheme=https;package=${siteConfig.packageName};end`;
}

export function InstallClient() {
  const params = useSearchParams();
  const [copied, setCopied] = useState(false);
  const { t } = useTranslations();

  const installUrl = useMemo(() => buildInstallUrl(new URLSearchParams(params)), [params]);
  const qrUrl = useMemo(() => buildQrUrl(installUrl), [installUrl]);
  const intentUrl = useMemo(() => buildAndroidIntentUrl(installUrl), [installUrl]);

  async function copy() {
    try {
      await navigator.clipboard.writeText(installUrl);
      setCopied(true);
      setTimeout(() => setCopied(false), 1200);
    } catch {
      // ignore
    }
  }

  return (
    <div className="grid gap-6">
      <section className="rounded-2xl border border-border bg-surface p-6 shadow-sm">
        <div className="grid gap-4 sm:grid-cols-[240px_1fr] sm:items-start">
          <div className="flex flex-col items-center gap-3">
            <div className="rounded-2xl border border-border bg-background p-3">
              {/* Using <img> to avoid Next image remote config */}
              <img src={qrUrl} alt={t("install.qrAlt")} width={240} height={240} />
            </div>
            <div className="text-sm text-muted-foreground">
              {t("install.qrHint")}
            </div>
          </div>

          <div className="space-y-3">
            <div className="text-sm font-semibold">{t("install.installLinkLabel")}</div>
            <div className="break-all rounded-xl border border-border bg-background px-4 py-3 text-sm">
              {installUrl}
            </div>

            <div className="flex flex-col gap-2 sm:flex-row">
              <button
                onClick={copy}
                className="inline-flex h-11 items-center justify-center rounded-xl border border-border bg-surface px-5 text-sm font-semibold text-foreground transition-colors hover:bg-muted"
                type="button"
              >
                {copied ? t("install.copied") : t("install.copyLink")}
              </button>

              <a
                href={installUrl}
                className="inline-flex h-11 items-center justify-center rounded-xl bg-accent px-5 text-sm font-semibold text-[color:var(--color-on-accent)] transition-opacity hover:opacity-95"
              >
                {t("install.openLink")}
              </a>

              <a
                href={intentUrl}
                className="inline-flex h-11 items-center justify-center rounded-xl border border-border bg-surface px-5 text-sm font-semibold text-foreground transition-colors hover:bg-muted"
              >
                {t("install.openInAppAndroid")}
              </a>
            </div>

            <div className="text-sm text-muted-foreground">
              {(() => {
                const example1 = "/install?tenant=...&ui=en";
                const example2 = "app=...";
                const tip = t("install.tip", { example1, example2 });
                if (typeof tip !== "string" || !tip.includes(example1) || !tip.includes(example2)) {
                  return tip;
                }
                const [before1, rest1] = tip.split(example1);
                const [between, after2] = rest1.split(example2);
                return (
                  <>
                    {before1}
                    <span className="font-mono">{example1}</span>
                    {between}
                    <span className="font-mono">{example2}</span>
                    {after2}
                  </>
                );
              })()}
            </div>
          </div>
        </div>
      </section>
    </div>
  );
}


