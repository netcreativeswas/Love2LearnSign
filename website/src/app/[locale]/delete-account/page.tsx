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
    title: `${translations.deleteAccount.title} - ${translations.common.appName}`,
    description: translations.deleteAccount.description,
    path: locale === "en" ? "/delete-account" : `/${locale}/delete-account`,
  });
}

function DeleteAccountPageContent({ locale }: { locale: Locale }) {
  const { t } = useTranslations();

  return (
    <div className="flex min-h-dvh flex-col bg-background text-foreground">
      <BreadcrumbList
        items={[
          { name: t("common.home"), url: siteConfig.url },
          { name: t("deleteAccount.title"), url: `${siteConfig.url}${getLocalizedPath("/delete-account", locale)}` },
        ]}
      />
      <StructuredData
        type="WebPage"
        data={{
          name: t("deleteAccount.title"),
          description: t("deleteAccount.description"),
          url: `${siteConfig.url}${getLocalizedPath("/delete-account", locale)}`,
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
                Send an email to{" "}
                <a
                  className="font-semibold text-foreground hover:underline"
                  href={`mailto:${siteConfig.supportEmail}?subject=${encodeURIComponent(
                    `Delete my ${siteConfig.appName} account`,
                  )}`}
                >
                  {siteConfig.supportEmail}
                </a>
                .
              </li>
              <li>
                Use the subject:{" "}
                <span className="font-semibold text-foreground">
                  Delete my {siteConfig.appName} account
                </span>
                .
              </li>
              <li>
                In the email body, include the email address you used to create
                your {siteConfig.appName} account.
              </li>
            </ol>
            <p className="mt-4 text-muted-foreground">
              We typically process account deletion requests within{" "}
              <span className="font-semibold text-foreground">
                7 business days
              </span>{" "}
              after verifying the request.
            </p>
          </SectionCard>

          <SectionCard title={t("deleteAccount.whatDeleted")}>
            <ul className="list-inside list-disc text-muted-foreground">
              <li>
                Your authentication account (Firebase Authentication) associated
                with your email address
              </li>
              <li>
                Your user profile stored in our database (e.g., display name,
                country, hearing status, app preferences, account status/approval)
              </li>
              <li>
                Usage counters linked to your account (e.g., video view counters,
                game session counters)
              </li>
              <li>
                Subscription access flags/roles stored in our systems (premium
                entitlement status)
              </li>
            </ul>
          </SectionCard>

          <SectionCard title={t("deleteAccount.whatKept")}>
            <ul className="list-inside list-disc text-muted-foreground">
              <li>
                <span className="font-semibold text-foreground">
                  Dictionary search analytics:
                </span>{" "}
                Anonymous search queries (sanitized text, timestamps, categories,
                result counts) are retained for app improvement purposes. These
                records are not linked to your account and cannot identify you.
              </li>
              <li>
                <span className="font-semibold text-foreground">
                  Aggregated usage statistics:
                </span>{" "}
                General app usage metrics (e.g., total video views, quiz
                completions) may be retained in aggregated form for analytics
                purposes, but these do not contain personally identifiable
                information.
              </li>
            </ul>
          </SectionCard>

          <SectionCard title={t("deleteAccount.optionalTitle")}>
            <p className="text-muted-foreground">
              If you want to remove specific data without deleting your entire
              account, you can contact us at{" "}
              <a
                className="font-semibold text-foreground hover:underline"
                href={`mailto:${siteConfig.supportEmail}`}
              >
                {siteConfig.supportEmail}
              </a>{" "}
              and specify what data you&apos;d like removed.
            </p>
          </SectionCard>
        </div>
      </PageShell>

      <SiteFooter />
    </div>
  );
}

export default async function DeleteAccountPage({ params }: { params: Promise<{ locale: Locale }> }) {
  const { locale } = await params;

  return (
    <TranslationProvider locale={locale}>
      <DeleteAccountPageContent locale={locale} />
    </TranslationProvider>
  );
}

