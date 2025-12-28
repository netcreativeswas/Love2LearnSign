"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { SiteHeader } from "@/components/SiteHeader";
import { SiteFooter } from "@/components/SiteFooter";
import { TranslationProvider, useTranslations } from "@/components/TranslationProvider";
import { Locale, getLocaleFromPath, getLocalizedPath } from "@/lib/i18n";

function NotFoundContent() {
  const pathname = usePathname();
  const locale = getLocaleFromPath(pathname);
  const { t } = useTranslations();

  return (
    <div className="flex min-h-dvh flex-col bg-background text-foreground">
      <SiteHeader />
      <main className="flex-1">
        <div className="mx-auto max-w-5xl px-4 py-12 sm:py-16">
          <div className="text-center">
            <h1 className="text-6xl font-bold text-foreground sm:text-8xl">{t("notFound.title")}</h1>
            <h2 className="mt-4 text-2xl font-semibold text-foreground sm:text-3xl">
              {t("notFound.heading")}
            </h2>
            <p className="mt-4 text-lg text-muted-foreground">
              {t("notFound.description")}
            </p>
            <div className="mt-8 flex flex-col items-center justify-center gap-4 sm:flex-row">
              <Link
                href={getLocalizedPath("/", locale)}
                className="rounded-xl bg-accent px-6 py-3 text-sm font-semibold text-on-accent transition-colors hover:bg-accent/90"
              >
                {t("notFound.goHome")}
              </Link>
              <Link
                href={getLocalizedPath("/contact", locale)}
                className="rounded-xl border border-border bg-surface px-6 py-3 text-sm font-semibold text-foreground transition-colors hover:bg-muted"
              >
                {t("notFound.contactSupport")}
              </Link>
            </div>
            <div className="mt-12">
              <p className="text-sm font-semibold text-foreground">{t("notFound.popularPages")}</p>
              <nav className="mt-4 flex flex-wrap justify-center gap-4">
                <Link
                  href={getLocalizedPath("/", locale)}
                  className="text-sm text-muted-foreground hover:text-foreground hover:underline"
                >
                  {t("common.home")}
                </Link>
                <Link
                  href={getLocalizedPath("/contact", locale)}
                  className="text-sm text-muted-foreground hover:text-foreground hover:underline"
                >
                  {t("common.contact")}
                </Link>
                <Link
                  href={getLocalizedPath("/donate", locale)}
                  className="text-sm text-muted-foreground hover:text-foreground hover:underline"
                >
                  {t("common.donate")}
                </Link>
                <Link
                  href={getLocalizedPath("/privacy", locale)}
                  className="text-sm text-muted-foreground hover:text-foreground hover:underline"
                >
                  {t("common.privacy")}
                </Link>
              </nav>
            </div>
          </div>
        </div>
      </main>
      <SiteFooter />
    </div>
  );
}

export default function NotFound({ params }: { params: { locale: Locale } }) {
  const pathname = usePathname();
  const locale = params?.locale || getLocaleFromPath(pathname || "");

  return (
    <TranslationProvider locale={locale}>
      <NotFoundContent />
    </TranslationProvider>
  );
}

