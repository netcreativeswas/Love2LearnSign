import Image from "next/image";
import Link from "next/link";

import { SiteFooter } from "@/components/SiteFooter";
import { SiteHeader } from "@/components/SiteHeader";
import { ImageSlider } from "@/components/ImageSlider";
import { siteConfig } from "@/lib/site-config";
import { generateMetadata as genMeta } from "@/lib/metadata";
import { StructuredData } from "@/components/StructuredData";
import { TranslationProvider, useTranslations } from "@/components/TranslationProvider";
import { Locale, getTranslations, getLocalizedPath } from "@/lib/i18n";

export async function generateMetadata({
  params,
}: {
  params: { locale: Locale };
}) {
  const locale = params.locale;
  const translations = getTranslations(locale);

  return genMeta({
    title: `${translations.home.title} - ${translations.common.appName}`,
    description: translations.home.description,
    path: locale === "en" ? "/" : `/${locale}`,
  });
}

function HomeContent({ locale }: { locale: Locale }) {
  const { t } = useTranslations();

  return (
    <div className="flex min-h-dvh flex-col bg-background text-foreground">
      <StructuredData
        type="WebSite"
        data={{
          name: siteConfig.appName,
          url: siteConfig.url,
          description: t("home.description"),
          potentialAction: {
            "@type": "SearchAction",
            target: {
              "@type": "EntryPoint",
              urlTemplate: `${siteConfig.url}/?q={search_term_string}`,
            },
            "query-input": "required name=search_term_string",
          },
        }}
      />
      <StructuredData
        type="Organization"
        data={{
          name: siteConfig.developerName,
          url: "https://netcreative-swas.net",
          logo: `${siteConfig.url}/brand/logo.png`,
        }}
      />
      <StructuredData
        type="MobileApplication"
        data={{
          name: siteConfig.appName,
          applicationCategory: "EducationalApplication",
          operatingSystem: "Android",
          offers: {
            "@type": "Offer",
            price: "0",
            priceCurrency: "USD",
          },
          aggregateRating: {
            "@type": "AggregateRating",
            ratingValue: "4.5",
            ratingCount: "100",
          },
        }}
      />
      <SiteHeader />

      <main className="flex-1">
        <div className="mx-auto max-w-5xl px-4 py-12 sm:py-16">
        <div className="grid items-center gap-10 lg:grid-cols-2">
          <div className="space-y-6">
            <div className="inline-flex items-center gap-2 rounded-full border border-border bg-surface px-4 py-2 text-sm text-muted-foreground">
              <span className="h-2 w-2 rounded-full bg-accent" />
              {t("home.tagline")}
            </div>

            <h1 className="text-balance text-4xl font-semibold tracking-tight sm:text-5xl">
              {t("home.title")}
            </h1>

            <p className="max-w-prose text-lg leading-8 text-muted-foreground">
              {t("home.description")}
            </p>

            <div className="flex flex-col gap-3 sm:flex-row sm:items-center">
              <a
                href={siteConfig.playStoreUrl}
                target="_blank"
                rel="noreferrer"
                className="inline-flex items-center justify-center transition-opacity hover:opacity-90"
              >
                <Image
                  src="/icons/google-play-download.png"
                  alt={t("home.getOnGooglePlay")}
                  width={180}
                  height={60}
                  className="h-auto w-auto"
                />
              </a>
              <Link
                href={getLocalizedPath("/contact", locale)}
                className="inline-flex h-12 items-center justify-center rounded-xl border border-border bg-surface px-5 text-sm font-semibold text-foreground transition-colors hover:bg-muted"
              >
                {t("home.ctaContact")}
              </Link>
            </div>
          </div>

          <div className="relative">
            <div className="absolute -inset-6 -z-10 rounded-3xl bg-accent/10 blur-2xl" />
            <div className="rounded-3xl border border-border bg-surface p-8 shadow-sm">
              <div className="flex items-center gap-4">
                <Image
                  src="/brand/logo.png"
                  alt={`${siteConfig.appName} logo`}
                  width={56}
                  height={56}
                  priority
                  className="rounded-full"
                />
                <div>
                  <div className="text-lg font-semibold">{t("common.appName")}</div>
                  <div className="text-sm text-muted-foreground">
                    {t("common.madeBy")} {siteConfig.developerName}
                  </div>
                </div>
              </div>

              <div className="mt-6 grid gap-3 sm:grid-cols-2">
                <div className="rounded-2xl bg-muted p-4">
                  <div className="text-sm font-semibold">{t("home.features.dictionary.title")}</div>
                  <div className="mt-1 text-sm text-muted-foreground">
                    {t("home.features.dictionary.description")}
                  </div>
                </div>
                <div className="rounded-2xl bg-muted p-4">
                  <div className="text-sm font-semibold">{t("home.features.quizzes.title")}</div>
                  <div className="mt-1 text-sm text-muted-foreground">
                    {t("home.features.quizzes.description")}
                  </div>
                </div>
                <div className="rounded-2xl bg-muted p-4">
                  <div className="text-sm font-semibold">{t("home.features.flashcards.title")}</div>
                  <div className="mt-1 text-sm text-muted-foreground">
                    {t("home.features.flashcards.description")}
                  </div>
                </div>
                <div className="rounded-2xl bg-muted p-4">
                  <div className="text-sm font-semibold">{t("home.features.offline.title")}</div>
                  <div className="mt-1 text-sm text-muted-foreground">
                    {t("home.features.offline.description")}
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>

        <ImageSlider />
        </div>
      </main>

      <SiteFooter />
    </div>
  );
}

export default function Home({ params }: { params: { locale: Locale } }) {
  const locale = params.locale;

  return (
    <TranslationProvider locale={locale}>
      <HomeContent locale={locale} />
    </TranslationProvider>
  );
}

