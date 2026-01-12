"use client";

import Image from "next/image";
import Link from "next/link";

import { SiteFooter } from "@/components/SiteFooter";
import { SiteHeader } from "@/components/SiteHeader";
import { ImageSlider } from "@/components/ImageSlider";
import { siteConfig } from "@/lib/site-config";
import { StructuredData } from "@/components/StructuredData";
import { TranslationProvider, useTranslations } from "@/components/TranslationProvider";
import { Locale, getLocalizedPath, locales, defaultLocale } from "@/lib/i18n";

// Metadata is handled in the root layout

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
          sameAs: siteConfig.socialLinks.map((link) => link.href),
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
                  alt={t("common.logoAlt", { appName: siteConfig.appName })}
                  width={56}
                  height={56}
                  priority
                  className="rounded-full"
                />
                <div>
                  <div className="text-lg font-semibold">{t("common.appName")}</div>
                  <div className="text-sm text-muted-foreground">
                    {(() => {
                      const company = "NetCreative";
                      const text = t("footer.madeByLine", { netcreative: company });
                      if (typeof text !== "string" || !text.includes(company)) {
                        return (
                          <>
                            {t("common.madeBy", { name: siteConfig.developerName })}
                          </>
                        );
                      }
                      const [before, after] = text.split(company);
                      return (
                        <>
                          {before}
                          <a
                            href="https://netcreative-swas.net"
                            target="_blank"
                            rel="noreferrer"
                            className="font-medium text-foreground hover:underline"
                          >
                            {company}
                          </a>
                          {after}
                        </>
                      );
                    })()}
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

        <section className="mt-12 rounded-3xl border border-border bg-surface p-8 shadow-sm">
          <div className="grid gap-8 lg:grid-cols-2">
            <div className="space-y-4">
              <h2 className="text-2xl font-semibold tracking-tight">
                {t("home.seo.learnTitle")}
              </h2>
              <p className="text-sm leading-7 text-muted-foreground">
                {t("home.seo.learnP1")}
              </p>
              <p className="text-sm leading-7 text-muted-foreground">
                {t("home.seo.learnP2")}
              </p>

              <h3 className="pt-2 text-lg font-semibold">{t("home.seo.whoTitle")}</h3>
              <p className="text-sm leading-7 text-muted-foreground">
                {t("home.seo.whoP1")}
              </p>
              <ul className="list-inside list-disc space-y-1 text-sm text-muted-foreground">
                <li>{t("home.seo.whoList1")}</li>
                <li>{t("home.seo.whoList2")}</li>
                <li>{t("home.seo.whoList3")}</li>
              </ul>
            </div>

            <div className="space-y-4">
              <h3 className="text-lg font-semibold">{t("home.seo.howTitle")}</h3>
              <ol className="list-inside list-decimal space-y-1 text-sm text-muted-foreground">
                <li>{t("home.seo.howList1")}</li>
                <li>{t("home.seo.howList2")}</li>
                <li>{t("home.seo.howList3")}</li>
                <li>{t("home.seo.howList4")}</li>
              </ol>

              <h3 className="pt-2 text-lg font-semibold">{t("home.seo.faqTitle")}</h3>
              <div className="space-y-3 text-sm">
                <div>
                  <div className="font-semibold">{t("home.seo.faqQ1")}</div>
                  <div className="text-muted-foreground">{t("home.seo.faqA1")}</div>
                </div>
                <div>
                  <div className="font-semibold">{t("home.seo.faqQ2")}</div>
                  <div className="text-muted-foreground">{t("home.seo.faqA2")}</div>
                </div>
                <div>
                  <div className="font-semibold">{t("home.seo.faqQ3")}</div>
                  <div className="text-muted-foreground">
                    {t("home.seo.faqA3")}{" "}
                    <Link
                      className="font-semibold text-foreground hover:underline"
                      href={getLocalizedPath("/collaboration", locale)}
                    >
                      {t("home.seo.faqLinkText")}
                    </Link>
                  </div>
                </div>
              </div>

              <div className="pt-2">
                <Link
                  href={getLocalizedPath("/contact", locale)}
                  className="text-sm font-semibold text-foreground hover:underline"
                >
                  {t("home.ctaContact")}
                </Link>
              </div>
            </div>
          </div>
        </section>

        <section className="mt-12 rounded-3xl border border-border bg-surface p-8 shadow-sm">
          <div className="grid items-start gap-8 lg:grid-cols-2">
            <div className="space-y-4">
              <h2 className="text-2xl font-semibold tracking-tight">
                {t("home.collaborationBlock.title")}
              </h2>
              <p className="text-sm leading-7 text-muted-foreground">
                {t("home.collaborationBlock.body")}
              </p>
              <div className="flex flex-col gap-3 sm:flex-row sm:items-center">
                <Link
                  href={getLocalizedPath("/collaboration", locale)}
                  className="inline-flex h-12 items-center justify-center rounded-xl border border-border bg-surface px-5 text-sm font-semibold text-foreground transition-colors hover:bg-muted"
                >
                  {t("home.collaborationBlock.ctaPrimary")}
                </Link>
                <Link
                  href={getLocalizedPath("/contact", locale)}
                  className="text-sm font-semibold text-foreground hover:underline"
                >
                  {t("home.collaborationBlock.ctaSecondary")}
                </Link>
              </div>
            </div>

            <div className="grid gap-3 sm:grid-cols-2">
              <div className="rounded-2xl bg-muted p-4">
                <div className="text-sm font-semibold">{t("home.collaborationBlock.card1Title")}</div>
                <div className="mt-1 text-sm text-muted-foreground">
                  {t("home.collaborationBlock.card1Body")}
                </div>
              </div>
              <div className="rounded-2xl bg-muted p-4">
                <div className="text-sm font-semibold">{t("home.collaborationBlock.card2Title")}</div>
                <div className="mt-1 text-sm text-muted-foreground">
                  {t("home.collaborationBlock.card2Body")}
                </div>
              </div>
              <div className="rounded-2xl bg-muted p-4 sm:col-span-2">
                <div className="text-sm font-semibold">{t("home.collaborationBlock.card3Title")}</div>
                <div className="mt-1 text-sm text-muted-foreground">
                  {t("home.collaborationBlock.card3Body")}
                </div>
              </div>
            </div>
          </div>
        </section>
        </div>
      </main>

      <SiteFooter />
    </div>
  );
}

export default async function Home({ params }: { params: Promise<{ locale: string }> }) {
  const { locale } = await params;
  const resolvedLocale = (locales.includes(locale as Locale) ? locale : defaultLocale) as Locale;

  return (
    <TranslationProvider locale={resolvedLocale}>
      <HomeContent locale={resolvedLocale} />
    </TranslationProvider>
  );
}

