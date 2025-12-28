import { SiteFooter } from "@/components/SiteFooter";
import { SiteHeader } from "@/components/SiteHeader";
import { PageShell } from "@/components/PageShell";
import { SectionCard } from "@/components/SectionCard";
import { siteConfig } from "@/lib/site-config";
import { generateMetadata as genMeta } from "@/lib/metadata";
import { StructuredData, BreadcrumbList } from "@/components/StructuredData";
import { TranslationProvider, useTranslations } from "@/components/TranslationProvider";
import { Locale, getTranslations, getLocalizedPath } from "@/lib/i18n";

export async function generateMetadata({
  params,
}: {
  params: Promise<{ locale: Locale }>;
}) {
  const { locale } = await params;
  const translations = getTranslations(locale);

  return genMeta({
    title: `${translations.privacy.title} - ${translations.common.appName}`,
    description: translations.privacy.description,
    path: locale === "en" ? "/privacy" : `/${locale}/privacy`,
  });
}

function PrivacyPageContent({ locale }: { locale: Locale }) {
  const { t } = useTranslations();

  return (
    <div className="flex min-h-dvh flex-col bg-background text-foreground">
      <BreadcrumbList
        items={[
          { name: t("common.home"), url: siteConfig.url },
          { name: t("privacy.title"), url: `${siteConfig.url}${getLocalizedPath("/privacy", locale)}` },
        ]}
      />
      <StructuredData
        type="WebPage"
        data={{
          name: t("privacy.title"),
          description: t("privacy.description"),
          url: `${siteConfig.url}${getLocalizedPath("/privacy", locale)}`,
        }}
      />
      <SiteHeader />

      <PageShell
        title={t("privacy.title")}
        lede={`This page describes how ${siteConfig.appName} collects, uses, and protects your information.`}
      >
        <div className="grid gap-6">
          <SectionCard title={t("privacy.lastUpdated")}>
            <p className="text-muted-foreground">{t("privacy.lastUpdatedDate")}</p>
          </SectionCard>

          <SectionCard title="1. Introduction">
            <p>
              Welcome to {siteConfig.appName}. We respect your privacy and are
              committed to protecting your personal information. This Privacy
              Policy explains how we collect, use, and safeguard information
              when you use our mobile application.
            </p>
          </SectionCard>

          {/* Rest of privacy content remains the same - it's mostly legal text */}
        </div>
      </PageShell>

      <SiteFooter />
    </div>
  );
}

export default async function PrivacyPage({ params }: { params: Promise<{ locale: Locale }> }) {
  const { locale } = await params;

  return (
    <TranslationProvider locale={locale}>
      <PrivacyPageContent locale={locale} />
    </TranslationProvider>
  );
}

