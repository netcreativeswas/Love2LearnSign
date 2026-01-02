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
function DeleteAccountPageContent() {
  const { t, translations } = useTranslations();

  const subject = t("deleteAccount.mailSubject", { appName: siteConfig.appName });
  const step1 = t("deleteAccount.requestStep1", { email: siteConfig.supportEmail });
  const step2 = t("deleteAccount.requestStep2", { subject });
  const step3 = t("deleteAccount.requestStep3", { appName: siteConfig.appName });
  const processingTime = t("deleteAccount.processingTime", { days: "7" });

  const whatDeletedItems =
    (translations.deleteAccount as Record<string, unknown>).whatDeletedItems as string[] | undefined;
  const whatKeptItems =
    (translations.deleteAccount as Record<string, unknown>).whatKeptItems as string[] | undefined;
  const optionalItems =
    (translations.deleteAccount as Record<string, unknown>).optionalItems as string[] | undefined;

  return (
    <div className="flex min-h-dvh flex-col bg-background text-foreground">
      <BreadcrumbList
        items={[
          { name: t("common.home"), url: siteConfig.url },
          { name: t("deleteAccount.title"), url: `${siteConfig.url}/delete-account` },
        ]}
      />
      <StructuredData
        type="WebPage"
        data={{
          name: t("deleteAccount.title"),
          description: t("deleteAccount.description"),
          url: `${siteConfig.url}/delete-account`,
        }}
      />
      <SiteHeader />

      <PageShell
        title={t("deleteAccount.pageTitle")}
        lede={t("deleteAccount.descriptionText", {
          appName: siteConfig.appName,
          developerName: siteConfig.developerName,
        })}
      >
        <div className="grid gap-6">
          <SectionCard title={t("deleteAccount.requestTitle")}>
            <ol className="list-inside list-decimal space-y-2 text-muted-foreground">
              <li>
                {(() => {
                  const email = siteConfig.supportEmail;
                  if (!step1.includes(email)) return step1;
                  const [before, after] = step1.split(email);
                  return (
                    <>
                      {before}
                      <a
                        className="font-semibold text-foreground hover:underline"
                        href={`mailto:${email}?subject=${encodeURIComponent(subject)}`}
                      >
                        {email}
                      </a>
                      {after}
                    </>
                  );
                })()}
              </li>
              <li>
                {(() => {
                  if (!step2.includes(subject)) return step2;
                  const [before, after] = step2.split(subject);
                  return (
                    <>
                      {before}
                      <span className="font-semibold text-foreground">{subject}</span>
                      {after}
                    </>
                  );
                })()}
              </li>
              <li>{step3}</li>
            </ol>
            <p className="mt-4 text-muted-foreground">
              {processingTime}
            </p>
          </SectionCard>

          <SectionCard title={t("deleteAccount.whatDeleted")}>
            <ul className="list-inside list-disc text-muted-foreground">
              {(whatDeletedItems ?? []).map((item) => (
                <li key={item}>{item}</li>
              ))}
            </ul>
          </SectionCard>

          <SectionCard title={t("deleteAccount.whatKept")}>
            <ul className="list-inside list-disc text-muted-foreground">
              {(whatKeptItems ?? []).map((item) => (
                <li key={item}>{item}</li>
              ))}
            </ul>
          </SectionCard>

          <SectionCard title={t("deleteAccount.optionalTitle")}>
            <p className="text-muted-foreground">{t("deleteAccount.optionalIntro")}</p>
            <ul className="mt-2 list-inside list-disc text-muted-foreground">
              {(optionalItems ?? []).map((item) => {
                const email = siteConfig.supportEmail;
                if (!item.includes(email)) return <li key={item}>{item}</li>;
                const [before, after] = item.split(email);
                return (
                  <li key={item}>
                    {before}
                    <a
                      className="font-semibold text-foreground hover:underline"
                      href={`mailto:${email}`}
                    >
                      {email}
                    </a>
                    {after}
                  </li>
                );
              })}
            </ul>
          </SectionCard>
        </div>
      </PageShell>

      <SiteFooter />
    </div>
  );
}

export default function DeleteAccountPage() {
  return (
    <TranslationProvider locale={locale}>
      <DeleteAccountPageContent />
    </TranslationProvider>
  );
}


