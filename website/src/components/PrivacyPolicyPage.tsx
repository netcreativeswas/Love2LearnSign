"use client";

import { SiteFooter } from "@/components/SiteFooter";
import { SiteHeader } from "@/components/SiteHeader";
import { PageShell } from "@/components/PageShell";
import { SectionCard } from "@/components/SectionCard";
import { siteConfig } from "@/lib/site-config";
import { BreadcrumbList, StructuredData } from "@/components/StructuredData";
import { useTranslations } from "@/components/TranslationProvider";
import { getLocalizedPath, type Locale } from "@/lib/i18n";

type PolicyList = {
  title: string;
  items: string[];
};

type PolicySection = {
  id: string;
  title: string;
  paragraphs?: string[];
  lists?: PolicyList[];
};

function interpolate(text: string) {
  return text
    .replaceAll("{appName}", siteConfig.appName)
    .replaceAll("{developerName}", siteConfig.developerName)
    .replaceAll("{supportEmail}", siteConfig.supportEmail)
    .replaceAll("{siteUrl}", siteConfig.url)
    .replaceAll("{packageName}", siteConfig.packageName)
    .replaceAll("{playStoreUrl}", siteConfig.playStoreUrl);
}

function renderTextWithEmailLink(text: string) {
  const email = siteConfig.supportEmail;
  if (!email || !text.includes(email)) return text;
  const [before, after] = text.split(email);
  return (
    <>
      {before}
      <a className="font-semibold text-foreground hover:underline" href={`mailto:${email}`}>
        {email}
      </a>
      {after}
    </>
  );
}

export function PrivacyPolicyPage({ locale }: { locale: Locale }) {
  const { t, translations } = useTranslations();
  const path = getLocalizedPath("/privacy", locale);
  const url = `${siteConfig.url}${path}`;

  const sections = (translations.privacy as Record<string, unknown>).sections as
    | PolicySection[]
    | undefined;

  return (
    <div className="flex min-h-dvh flex-col bg-background text-foreground">
      <BreadcrumbList
        items={[
          { name: t("common.home"), url: siteConfig.url },
          { name: t("privacy.title"), url },
        ]}
      />
      <StructuredData
        type="WebPage"
        data={{
          name: t("privacy.title"),
          description: t("privacy.description"),
          url,
        }}
      />
      <SiteHeader />

      <PageShell
        title={t("privacy.title")}
        lede={t("privacy.lede", { appName: siteConfig.appName })}
      >
        <div className="grid gap-6">
          <SectionCard title={t("privacy.lastUpdated")}>
            <p className="text-muted-foreground">{t("privacy.lastUpdatedDate")}</p>
          </SectionCard>

          <SectionCard title={t("privacy.disclaimerTitle")}>
            <p className="text-muted-foreground">
              {renderTextWithEmailLink(interpolate(t("privacy.disclaimerBody")))}
            </p>
          </SectionCard>

          {(sections ?? []).map((section) => (
            <SectionCard key={section.id} title={interpolate(section.title)}>
              <div className="space-y-4">
                {(section.paragraphs ?? []).map((p) => (
                  <p key={p} className="text-muted-foreground">
                    {renderTextWithEmailLink(interpolate(p))}
                  </p>
                ))}

                {(section.lists ?? []).map((list) => (
                  <div key={list.title}>
                    <p className="font-semibold">{interpolate(list.title)}</p>
                    <ul className="mt-2 list-inside list-disc text-muted-foreground">
                      {list.items.map((item) => (
                        <li key={item}>{renderTextWithEmailLink(interpolate(item))}</li>
                      ))}
                    </ul>
                  </div>
                ))}
              </div>
            </SectionCard>
          ))}
        </div>
      </PageShell>

      <SiteFooter />
    </div>
  );
}


