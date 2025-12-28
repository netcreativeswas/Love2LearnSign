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
  const { t } = useTranslations();
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

          <SectionCard title="What data is deleted">
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
                  Store purchase records
                </span>{" "}
                are processed and retained by Google Play (and/or Apple App Store)
                under their own policies. We do not control those records.
              </li>
              <li>
                <span className="font-semibold text-foreground">
                  Accounting / legal records
                </span>{" "}
                may be retained for the period required by applicable laws (for
                example, records related to subscription transactions).
              </li>
              <li>
                <span className="font-semibold text-foreground">
                  Anonymous dictionary search analytics
                </span>{" "}
                are stored without personal identifiers (no email/user ID). Because
                they are not linked to your identity, they cannot be selectively
                deleted per user and may be kept in aggregate.
              </li>
            </ul>
          </SectionCard>

          <SectionCard title={t("deleteAccount.optionalTitle")}>
            <p className="text-muted-foreground">
              If you only want to remove certain data:
            </p>
            <ul className="mt-2 list-inside list-disc text-muted-foreground">
              <li>
                You can clear locally stored data (such as favorites, history, and
                cached videos) from within the app, or by clearing the app’s storage
                / uninstalling the app.
              </li>
              <li>
                You can also email{" "}
                <a
                  className="font-semibold text-foreground hover:underline"
                  href={`mailto:${siteConfig.supportEmail}`}
                >
                  {siteConfig.supportEmail}
                </a>{" "}
                to request deletion of specific account-linked data without deleting
                your entire account (when technically possible).
              </li>
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


