import type { Metadata } from "next";
import { Suspense } from "react";

import { SiteFooter } from "@/components/SiteFooter";
import { SiteHeader } from "@/components/SiteHeader";
import { PageShell } from "@/components/PageShell";
import { InstallClient } from "./InstallClient";
import { TranslationProvider } from "@/components/TranslationProvider";
import { defaultLocale, locales, type Locale, getTranslations } from "@/lib/i18n";

// /install depends on query params (tenant/app/ui) → force dynamic rendering.
export const dynamic = "force-dynamic";

export const metadata: Metadata = {
  title: "Install",
  description: "Install link generator for co-brand tenants.",
  alternates: { canonical: "/install" },
  robots: {
    index: false,
    follow: false,
    nocache: true,
    googleBot: { index: false, follow: false, noimageindex: true },
  },
};

export default function InstallPage({
  searchParams,
}: {
  searchParams?: Record<string, string | string[] | undefined>;
}) {
  const ui = searchParams?.ui ?? searchParams?.locale;
  const uiStr = Array.isArray(ui) ? ui[0] : ui;
  const resolvedLocale = (locales.includes(uiStr as Locale) ? uiStr : defaultLocale) as Locale;
  const tr = getTranslations(resolvedLocale);

  return (
    <TranslationProvider locale={resolvedLocale}>
      <div className="flex min-h-dvh flex-col bg-background text-foreground">
        <SiteHeader />
        <PageShell title={tr.install.pageTitle} lede={tr.install.pageLede}>
          <Suspense
            fallback={
              <div className="rounded-2xl border border-border bg-surface p-6 text-sm text-muted-foreground shadow-sm">
                {tr.install.loading}
              </div>
            }
          >
            <InstallClient />
          </Suspense>
        </PageShell>
        <SiteFooter />
      </div>
    </TranslationProvider>
  );
}


