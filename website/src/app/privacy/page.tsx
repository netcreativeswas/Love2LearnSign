import { SiteFooter } from "@/components/SiteFooter";
import { SiteHeader } from "@/components/SiteHeader";
import { PageShell } from "@/components/PageShell";
import { SectionCard } from "@/components/SectionCard";
import { siteConfig } from "@/lib/site-config";
import { generateMetadata as genMeta } from "@/lib/metadata";
import { StructuredData, BreadcrumbList } from "@/components/StructuredData";

export const metadata = genMeta({
  title: "Privacy Policy - Love to Learn Sign",
  description:
    "Privacy Policy for Love to Learn Sign. Learn how we collect, use, and protect your information when you use our Bangla Sign Language learning app.",
  path: "/privacy",
});

export default function PrivacyPage() {
  return (
    <div className="flex min-h-dvh flex-col bg-background text-foreground">
      <BreadcrumbList
        items={[
          { name: "Home", url: siteConfig.url },
          { name: "Privacy Policy", url: `${siteConfig.url}/privacy` },
        ]}
      />
      <StructuredData
        type="WebPage"
        data={{
          name: "Privacy Policy",
          description:
            "Privacy Policy for Love to Learn Sign. Learn how we collect, use, and protect your information.",
          url: `${siteConfig.url}/privacy`,
        }}
      />
      <SiteHeader />

      <PageShell
        title="Privacy Policy"
        lede={`This page describes how ${siteConfig.appName} collects, uses, and protects your information.`}
      >
        <div className="grid gap-6">
          <SectionCard title="Last updated">
            <p className="text-muted-foreground">27 December 2025</p>
          </SectionCard>

          <SectionCard title="1. Introduction">
            <p>
              Welcome to {siteConfig.appName}. We respect your privacy and are
              committed to protecting your personal information. This Privacy
              Policy explains how we collect, use, and safeguard information
              when you use our mobile application.
            </p>
          </SectionCard>

          <SectionCard title="2. Information we collect">
            <div className="space-y-4">
              <div>
                <p className="font-semibold">2.1 Information you provide</p>
                <ul className="mt-2 list-inside list-disc text-muted-foreground">
                  <li>Email address (for account creation and sign-in)</li>
                  <li>Display name</li>
                  <li>
                    Demographic information (optional): hearing status (hearing
                    person / hearing impaired)
                  </li>
                  <li>Country selection</li>
                  <li>Language preferences (English/Bengali)</li>
                  <li>Quiz settings (time limits, question counts)</li>
                  <li>Favorites (saved words and signs)</li>
                  <li>Quiz history (completed quizzes and scores)</li>
                  <li>Notification preferences (daily reminder settings)</li>
                  <li>Subscription preferences (premium choices)</li>
                  <li>Optional notes you choose to provide during signup</li>
                </ul>
              </div>

              <div>
                <p className="font-semibold">2.2 Information collected automatically</p>
                <ul className="mt-2 list-inside list-disc text-muted-foreground">
                  <li>Device information (operating system, device model)</li>
                  <li>App usage data (features used, time spent, video views)</li>
                  <li>Performance data (app crashes, errors)</li>
                  <li>Cache data (downloaded video content for offline viewing)</li>
                  <li>
                    Video view counters (to determine when to show advertisements)
                  </li>
                  <li>Game session data (flashcard and quiz usage)</li>
                  <li>
                    Ad interaction data (collected by Google AdMob — see Third‑Party
                    Services)
                  </li>
                  <li>
                    Dictionary search analytics (sanitized query text, timestamp,
                    category, result count, found/missing flag, anonymous session ID)
                  </li>
                </ul>
              </div>

              <div>
                <p className="font-semibold">2.3 Account and authentication data</p>
                <ul className="mt-2 list-inside list-disc text-muted-foreground">
                  <li>Email address (stored via Firebase Authentication)</li>
                  <li>User ID (unique identifier assigned by Firebase)</li>
                  <li>Email verification status</li>
                  <li>User account status (pending approval / approved)</li>
                  <li>User roles and permissions (e.g., paid user / admin / editor)</li>
                </ul>
              </div>

              <div>
                <p className="font-semibold">2.4 Premium subscription data</p>
                <ul className="mt-2 list-inside list-disc text-muted-foreground">
                  <li>Subscription type (monthly or yearly)</li>
                  <li>Subscription start and renewal dates</li>
                  <li>Subscription platform (Android or iOS)</li>
                  <li>
                    Payment information is processed by Google Play or Apple App Store
                    (we do not store payment card details)
                  </li>
                  <li>Subscription status (active/inactive)</li>
                </ul>
              </div>

              <div>
                <p className="font-semibold">2.5 Permissions required</p>
                <ul className="mt-2 list-inside list-disc text-muted-foreground">
                  <li>Internet access (video streaming, sync, ads)</li>
                  <li>Post notifications (daily reminders)</li>
                  <li>Schedule exact alarms (precise notification timing)</li>
                </ul>
              </div>

              <div>
                <p className="font-semibold">2.6 Search analytics (anonymous)</p>
                <ul className="mt-2 list-inside list-disc text-muted-foreground">
                  <li>
                    We log dictionary searches with sanitized query text, timestamp,
                    category, result count, and found/missing flag.
                  </li>
                  <li>
                    Search analytics do not store your email, user ID, or any other
                    personal identifier.
                  </li>
                  <li>
                    The data is used in aggregate to identify missing words and
                    improve search quality.
                  </li>
                </ul>
              </div>
            </div>
          </SectionCard>

          <SectionCard title="3. How we use your information">
            <ul className="list-inside list-disc text-muted-foreground">
              <li>Provide and maintain the app service</li>
              <li>Authenticate and manage user accounts</li>
              <li>Personalize the learning experience</li>
              <li>Send daily reminder notifications</li>
              <li>Manage premium subscriptions and access</li>
              <li>Display advertisements for non‑premium users</li>
              <li>Track video views and game sessions to determine ad frequency</li>
              <li>
                Analyze anonymous search analytics to identify missing words and improve
                dictionary relevance
              </li>
              <li>Improve performance and user experience</li>
              <li>Cache video content locally for offline access</li>
            </ul>
          </SectionCard>

          <SectionCard title="4. Third‑party services">
            <div className="space-y-4">
              <div>
                <p className="font-semibold">4.1 Firebase</p>
                <ul className="mt-2 list-inside list-disc text-muted-foreground">
                  <li>Firebase Authentication (accounts & sign‑in)</li>
                  <li>Firestore Database (content, preferences, counters)</li>
                  <li>Firebase Hosting (video content delivery)</li>
                  <li>Cloud Functions (subscription updates, roles)</li>
                </ul>
              </div>
              <div>
                <p className="font-semibold">4.2 Google Mobile Ads (AdMob)</p>
                <ul className="mt-2 list-inside list-disc text-muted-foreground">
                  <li>Interstitial ads (shown based on app usage)</li>
                  <li>Rewarded ads (to unlock additional game sessions)</li>
                  <li>Ad interaction data and advertising identifiers (as applicable)</li>
                  <li>
                    Google’s privacy policy:{" "}
                    <a
                      className="text-foreground hover:underline"
                      href="https://policies.google.com/privacy"
                      target="_blank"
                      rel="noreferrer"
                    >
                      https://policies.google.com/privacy
                    </a>
                  </li>
                </ul>
              </div>
              <div>
                <p className="font-semibold">4.3 In‑app purchases</p>
                <ul className="mt-2 list-inside list-disc text-muted-foreground">
                  <li>Google Play Billing (Android)</li>
                  <li>Apple App Store In‑App Purchase (iOS)</li>
                  <li>We do not store payment card information</li>
                </ul>
              </div>
            </div>
          </SectionCard>

          <SectionCard title="5. Data storage and retention">
            <div className="space-y-4">
              <div>
                <p className="font-semibold">5.1 Local storage</p>
                <ul className="mt-2 list-inside list-disc text-muted-foreground">
                  <li>Settings, favorites, and cached videos may be stored on your device</li>
                  <li>Counters/session data may be stored locally for guest users</li>
                </ul>
              </div>
              <div>
                <p className="font-semibold">5.2 Cloud storage</p>
                <ul className="mt-2 list-inside list-disc text-muted-foreground">
                  <li>Account and profile information is stored in Firebase</li>
                  <li>Subscription status and access flags may be stored in Firestore</li>
                  <li>Usage counters (video views, game sessions) may be stored in Firestore</li>
                  <li>
                    Anonymous search analytics entries are stored in Firestore to improve
                    content coverage
                  </li>
                </ul>
              </div>
              <div>
                <p className="font-semibold">5.3 Retention</p>
                <ul className="mt-2 list-inside list-disc text-muted-foreground">
                  <li>Local data is removed when you uninstall the app</li>
                  <li>Account data is retained until you request account deletion</li>
                  <li>
                    Subscription-related records may be retained for legal and accounting
                    purposes as required by law
                  </li>
                </ul>
              </div>
            </div>
          </SectionCard>

          <SectionCard title="6. Your rights">
            <ul className="list-inside list-disc text-muted-foreground">
              <li>Access and modify your preferences through the app</li>
              <li>Control notifications and language preferences</li>
              <li>Cancel your subscription via Google Play / App Store settings</li>
              <li>
                Request account deletion and associated data deletion (see{" "}
                <a className="text-foreground hover:underline" href="/delete-account">
                  Delete account
                </a>
                )
              </li>
              <li>Opt‑out of personalized ads by resetting your Advertising ID (device settings)</li>
            </ul>
          </SectionCard>

          <SectionCard title="7. Children’s privacy">
            <p className="text-muted-foreground">
              We do not knowingly collect personal data from children under 13. If you
              believe a child has provided personal information, contact us and we will
              delete it.
            </p>
          </SectionCard>

          <SectionCard title="8. International use">
            <p className="text-muted-foreground">
              Data may be processed and stored in countries with different data protection
              laws. By using the app, you consent to this transfer.
            </p>
          </SectionCard>

          <SectionCard title="9. Changes to this policy">
            <p className="text-muted-foreground">
              We may update this policy from time to time. Updates will be posted in-app
              and reflected on this page.
            </p>
          </SectionCard>

          <SectionCard title="10. Contact">
            <p className="text-muted-foreground">
              For privacy questions or data deletion requests, contact{" "}
              <a
                className="font-semibold text-foreground hover:underline"
                href={`mailto:${siteConfig.supportEmail}`}
              >
                {siteConfig.supportEmail}
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


