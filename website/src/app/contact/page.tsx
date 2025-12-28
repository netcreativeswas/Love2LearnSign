"use client";

import { SiteFooter } from "@/components/SiteFooter";
import { SiteHeader } from "@/components/SiteHeader";
import { PageShell } from "@/components/PageShell";
import { SectionCard } from "@/components/SectionCard";
import { siteConfig } from "@/lib/site-config";
import { StructuredData, BreadcrumbList } from "@/components/StructuredData";
import { TranslationProvider, useTranslations } from "@/components/TranslationProvider";
import { defaultLocale, getLocalizedPath } from "@/lib/i18n";

const locale = defaultLocale;

// Metadata is handled in the root layout
function ContactPageContent() {
  const { t } = useTranslations();
  return (
    <div className="flex min-h-dvh flex-col bg-background text-foreground">
      <BreadcrumbList
        items={[
          { name: t("common.home"), url: siteConfig.url },
          { name: t("contact.title"), url: `${siteConfig.url}/contact` },
        ]}
      />
      <StructuredData
        type="WebPage"
        data={{
          name: t("contact.title"),
          description: t("contact.description"),
          url: `${siteConfig.url}/contact`,
        }}
      />
      <SiteHeader />

      <PageShell
        title={t("contact.title")}
        lede={t("contact.description")}
      >
        <div className="grid gap-6">
          <SectionCard title={t("contact.emailSupport.title")}>
            <p>
              {t("contact.emailSupport.text", {
                appName: siteConfig.appName,
                email: siteConfig.supportEmail,
              })}
            </p>
            <p className="text-muted-foreground">
              {t("contact.emailSupport.note")}
            </p>
          </SectionCard>

          <SectionCard title={t("contact.quickLinks.title")}>
            <ul className="list-inside list-disc text-muted-foreground">
              <li>
                <a className="hover:underline" href={siteConfig.playStoreUrl}>
                  {t("contact.quickLinks.googlePlay")}
                </a>
              </li>
              <li>
                <a className="hover:underline" href={getLocalizedPath("/privacy", locale)}>
                  {t("contact.quickLinks.privacy")}
                </a>
              </li>
              <li>
                <a className="hover:underline" href={getLocalizedPath("/delete-account", locale)}>
                  {t("contact.quickLinks.deleteAccount")}
                </a>
              </li>
            </ul>
          </SectionCard>

          <SectionCard title={t("contact.about.title")}>
            <p className="text-muted-foreground">
              {t("contact.about.text1", { netcreative: "NetCreative" })}{" "}
              <a
                href="https://netcreative-swas.net"
                target="_blank"
                rel="noreferrer"
                className="font-semibold text-foreground hover:underline"
              >
                NetCreative
              </a>
              , {t("contact.about.text1Part2")}
            </p>
            <p className="mt-4 text-muted-foreground">
              {t("contact.about.text2")}
            </p>
            <p className="mt-4 text-muted-foreground">
              {t("contact.about.text3", { website: "netcreative-swas.net" })}{" "}
              <a
                href="https://netcreative-swas.net"
                target="_blank"
                rel="noreferrer"
                className="font-semibold text-foreground hover:underline"
              >
                netcreative-swas.net
              </a>
              .
            </p>
          </SectionCard>
        </div>
      </PageShell>

      <SiteFooter />
    </div>
  );
}

export default function ContactPage() {
  return (
    <TranslationProvider locale={locale}>
      <ContactPageContent />
    </TranslationProvider>
  );
}


