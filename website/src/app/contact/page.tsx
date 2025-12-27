import { SiteFooter } from "@/components/SiteFooter";
import { SiteHeader } from "@/components/SiteHeader";
import { PageShell } from "@/components/PageShell";
import { SectionCard } from "@/components/SectionCard";
import { siteConfig } from "@/lib/site-config";

export const metadata = {
  title: "Contact",
};

export default function ContactPage() {
  return (
    <div className="min-h-dvh bg-background text-foreground">
      <SiteHeader />

      <PageShell
        title="Contact"
        lede="Need help with the app, subscriptions, or your account? Reach out to us by email."
      >
        <div className="grid gap-6">
          <SectionCard title="Email support">
            <p>
              For {siteConfig.appName} support, email{" "}
              <a
                className="font-semibold text-foreground hover:underline"
                href={`mailto:${siteConfig.supportEmail}`}
              >
                {siteConfig.supportEmail}
              </a>
              .
            </p>
            <p className="text-muted-foreground">
              Please include the email address you use in the app and a short
              description of the issue.
            </p>
          </SectionCard>

          <SectionCard title="Quick links">
            <ul className="list-inside list-disc text-muted-foreground">
              <li>
                <a className="hover:underline" href={siteConfig.playStoreUrl}>
                  Google Play listing
                </a>
              </li>
              <li>
                <a className="hover:underline" href="/privacy">
                  Privacy Policy
                </a>
              </li>
              <li>
                <a className="hover:underline" href="/delete-account">
                  Delete account instructions
                </a>
              </li>
            </ul>
          </SectionCard>
        </div>
      </PageShell>

      <SiteFooter />
    </div>
  );
}


