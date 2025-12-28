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
    <div className="flex min-h-dvh flex-col bg-background text-foreground">
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

          <SectionCard title="About">
            <p className="text-muted-foreground">
              This application was developed by{" "}
              <a
                href="https://netcreative-swas.net"
                target="_blank"
                rel="noreferrer"
                className="font-semibold text-foreground hover:underline"
              >
                NetCreative
              </a>
              , a web development agency based in France. We specialize in
              creating modern, user-friendly websites and mobile applications
              that deliver exceptional user experiences.
            </p>
            <p className="mt-4 text-muted-foreground">
              Our team combines technical expertise with creative design to build
              digital solutions that meet the unique needs of our clients. From
              responsive web applications to native mobile apps, we are committed
              to delivering high-quality products that make a difference.
            </p>
            <p className="mt-4 text-muted-foreground">
              For more information about our services, visit{" "}
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


