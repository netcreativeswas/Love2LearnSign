import Link from "next/link";
import { SiteHeader } from "@/components/SiteHeader";
import { SiteFooter } from "@/components/SiteFooter";
import { PageShell } from "@/components/PageShell";
import { SectionCard } from "@/components/SectionCard";
import { StructuredData, BreadcrumbList } from "@/components/StructuredData";
import { siteConfig } from "@/lib/site-config";
import { Locale, getLocalizedPath } from "@/lib/i18n";

type FaqItem = {
  question: string;
  answer: string;
};

const faq: FaqItem[] = [
  {
    question: "What is co-branding?",
    answer:
      "Co-branding means we publish a dictionary experience powered by this platform while keeping Love to Learn Sign visible alongside your organization’s identity (name, logo, and messaging). It’s a fast way to launch with shared branding and shared maintenance.",
  },
  {
    question: "What is white-label?",
    answer:
      "White-label means you get an app experience that is fully branded for your organization (your name, your visual identity, and your store presence). The platform remains the engine, but the product looks and feels like your own app.",
  },
  {
    question: "Do you support sign languages beyond Bangla Sign Language?",
    answer:
      "Yes. The platform is designed so other sign languages can benefit from the same learning flow: dictionary browsing, short videos, favorites, and practice features. Each dictionary can be handled as its own dedicated space.",
  },
  {
    question: "How does revenue sharing work (ads and subscriptions)?",
    answer:
      "We can organize monetization per dictionary. The general approach is that ad revenue for a given dictionary is paid back to the organization operating that dictionary on the platform. Subscription details depend on your setup, so we discuss the exact model together.",
  },
  {
    question: "Who owns the content?",
    answer:
      "You keep ownership of your sign language content. We focus on providing the product and platform so your dictionary can reach learners on mobile.",
  },
  {
    question: "How do we get started?",
    answer:
      "Send a message with your sign language, expected content size, and your preferred option (co-branding or white-label). We’ll reply with questions, a proposed setup, and next steps.",
  },
];

function buildFaqJsonLd(items: FaqItem[]) {
  return {
    mainEntity: items.map((item) => ({
      "@type": "Question",
      name: item.question,
      acceptedAnswer: {
        "@type": "Answer",
        text: item.answer,
      },
    })),
  } as const;
}

export function CollaborationPage({ locale }: { locale: Locale }) {
  const collaborationPath = getLocalizedPath("/collaboration", locale);
  const contactPath = getLocalizedPath("/contact", locale);

  const pageTitle = "Collaboration, Co-branding & White-label";
  const pageDescription =
    "Partner with Love to Learn Sign to make sign language learning more accessible. Launch a co-branded dictionary experience or a fully white-labeled app, with a revenue model organized per dictionary.";

  const pageUrl = `${siteConfig.url}${collaborationPath}`;
  const homeUrl = locale === "en" ? siteConfig.url : `${siteConfig.url}/bn`;

  return (
    <div className="flex min-h-dvh flex-col bg-background text-foreground">
      <BreadcrumbList
        items={[
          { name: "Home", url: homeUrl },
          { name: "Collaboration", url: pageUrl },
        ]}
      />
      <StructuredData
        type="WebPage"
        data={{
          name: pageTitle,
          description: pageDescription,
          url: pageUrl,
        }}
      />
      <StructuredData type="FAQPage" data={buildFaqJsonLd(faq)} />

      <SiteHeader />

      <PageShell title={pageTitle} lede={pageDescription}>
        <div className="grid gap-6">
          <section className="rounded-3xl border border-border bg-surface p-6 shadow-sm sm:p-8">
            <div className="grid items-start gap-8 lg:grid-cols-2">
              <div className="space-y-4">
                <h2 className="text-2xl font-semibold tracking-tight">
                  A platform built to share sign language — beyond a single dictionary
                </h2>
                <p className="text-sm leading-7 text-muted-foreground">
                  I built Love to Learn Sign because I care about making sign language learning more
                  accessible. Today, the website and app focus on Bangla Sign Language — and the same
                  approach can help other sign languages grow through a modern, learner-friendly
                  dictionary experience.
                </p>
                <p className="text-sm leading-7 text-muted-foreground">
                  If you represent a Deaf association, a school, a NGO, a community project, or a
                  dictionary owner, you can use this platform to publish and maintain your own
                  dictionary space and reach learners on mobile.
                </p>
                <div className="flex flex-col gap-3 sm:flex-row sm:items-center">
                  <Link
                    href={contactPath}
                    className="inline-flex h-12 items-center justify-center rounded-xl border border-border bg-surface px-5 text-sm font-semibold text-foreground transition-colors hover:bg-muted"
                  >
                    Contact us to discuss a partnership
                  </Link>
                  <a
                    href={`mailto:${siteConfig.supportEmail}`}
                    className="text-sm font-semibold text-foreground hover:underline"
                  >
                    Or email {siteConfig.supportEmail}
                  </a>
                </div>
              </div>

              <div className="relative">
                <div className="absolute -inset-6 -z-10 rounded-3xl bg-accent/10 blur-2xl" />
                <div className="rounded-3xl border border-border bg-muted p-6 sm:p-8">
                  <div className="text-sm font-semibold">What you get</div>
                  <ul className="mt-3 space-y-2 text-sm text-muted-foreground">
                    <li>Dictionary browsing with short videos</li>
                    <li>Favorites and learning flow features</li>
                    <li>Per-dictionary organization (multi-dictionary friendly)</li>
                    <li>Monetization options (ads + subscriptions) discussed case-by-case</li>
                  </ul>
                  <div className="mt-6 rounded-2xl bg-surface p-4">
                    <div className="text-sm font-semibold">Important</div>
                    <p className="mt-1 text-sm text-muted-foreground">
                      This page does not list pricing. We’ll shape the technical setup, branding,
                      and revenue model based on your needs.
                    </p>
                  </div>
                </div>
              </div>
            </div>
          </section>

          <SectionCard title="Two ways to partner">
            <div className="grid gap-4 lg:grid-cols-2">
              <div className="rounded-2xl border border-border bg-muted p-5">
                <div className="text-base font-semibold text-foreground">Co-branding</div>
                <p className="mt-2 text-sm text-muted-foreground">
                  Fast launch, shared branding. Your dictionary lives on the platform with your
                  identity visible alongside Love to Learn Sign.
                </p>
              </div>
              <div className="rounded-2xl border border-border bg-muted p-5">
                <div className="text-base font-semibold text-foreground">White-label</div>
                <p className="mt-2 text-sm text-muted-foreground">
                  Your own app name and brand. The platform powers the experience, but your users
                  see your identity first.
                </p>
              </div>
            </div>
          </SectionCard>

          <SectionCard title="Pros & cons (practical comparison)">
            <div className="grid gap-6 lg:grid-cols-2">
              <div className="rounded-2xl border border-border bg-surface p-5">
                <div className="text-base font-semibold">Co-branding</div>
                <div className="mt-4 grid gap-4 sm:grid-cols-2">
                  <div>
                    <div className="text-sm font-semibold">Pros</div>
                    <ul className="mt-2 list-inside list-disc space-y-1 text-sm text-muted-foreground">
                      <li>Faster to launch</li>
                      <li>Lower operational complexity</li>
                      <li>Shared maintenance and improvements</li>
                    </ul>
                  </div>
                  <div>
                    <div className="text-sm font-semibold">Cons</div>
                    <ul className="mt-2 list-inside list-disc space-y-1 text-sm text-muted-foreground">
                      <li>Shared branding presence</li>
                      <li>Less control over store identity</li>
                      <li>Some platform-wide UX constraints</li>
                    </ul>
                  </div>
                </div>
              </div>

              <div className="rounded-2xl border border-border bg-surface p-5">
                <div className="text-base font-semibold">White-label</div>
                <div className="mt-4 grid gap-4 sm:grid-cols-2">
                  <div>
                    <div className="text-sm font-semibold">Pros</div>
                    <ul className="mt-2 list-inside list-disc space-y-1 text-sm text-muted-foreground">
                      <li>Your own brand and app name</li>
                      <li>Clear ownership and positioning</li>
                      <li>More flexibility in presentation</li>
                    </ul>
                  </div>
                  <div>
                    <div className="text-sm font-semibold">Cons</div>
                    <ul className="mt-2 list-inside list-disc space-y-1 text-sm text-muted-foreground">
                      <li>More setup work</li>
                      <li>More decisions (branding, store, distribution)</li>
                      <li>Deeper technical discussion required</li>
                    </ul>
                  </div>
                </div>
              </div>
            </div>
          </SectionCard>

          <SectionCard title="How the platform works (in simple terms)">
            <div className="grid gap-4 lg:grid-cols-2">
              <div className="rounded-2xl bg-muted p-5">
                <div className="text-sm font-semibold">Per-dictionary setup</div>
                <p className="mt-2 text-sm text-muted-foreground">
                  Each dictionary can be treated as its own dedicated space (content, categories,
                  and visibility). This allows multiple sign languages to coexist while keeping
                  each one organized.
                </p>
              </div>
              <div className="rounded-2xl bg-muted p-5">
                <div className="text-sm font-semibold">Revenue model (no public pricing)</div>
                <p className="mt-2 text-sm text-muted-foreground">
                  Ads and subscriptions can be organized per dictionary. The principle is to return
                  ad revenue generated by a dictionary back to the organization operating that
                  dictionary on the platform. Subscription details depend on your option and scope.
                </p>
              </div>
            </div>
          </SectionCard>

          <SectionCard title="FAQ">
            <div className="grid gap-3">
              {faq.map((item) => (
                <details
                  key={item.question}
                  className="group rounded-2xl border border-border bg-surface p-5"
                >
                  <summary className="cursor-pointer list-none text-sm font-semibold text-foreground">
                    <span className="flex items-start justify-between gap-4">
                      <span>{item.question}</span>
                      <span className="mt-0.5 text-muted-foreground transition-transform group-open:rotate-45">
                        +
                      </span>
                    </span>
                  </summary>
                  <p className="mt-3 text-sm leading-7 text-muted-foreground">{item.answer}</p>
                </details>
              ))}
            </div>
          </SectionCard>

          <section className="rounded-3xl border border-border bg-surface p-6 shadow-sm sm:p-8">
            <div className="grid gap-6 lg:grid-cols-[1.2fr_0.8fr] lg:items-center">
              <div>
                <h2 className="text-xl font-semibold tracking-tight">Want to explore a partnership?</h2>
                <p className="mt-2 text-sm leading-7 text-muted-foreground">
                  Send a short message with your sign language, the size of your dictionary, and
                  your preferred option (co-branding or white-label). We’ll come back with a few
                  questions and a clear proposal.
                </p>
              </div>
              <div className="flex flex-col gap-3 sm:flex-row lg:flex-col">
                <Link
                  href={contactPath}
                  className="inline-flex h-12 items-center justify-center rounded-xl border border-border bg-surface px-5 text-sm font-semibold text-foreground transition-colors hover:bg-muted"
                >
                  Contact us
                </Link>
                <a
                  href={`mailto:${siteConfig.supportEmail}`}
                  className="inline-flex h-12 items-center justify-center rounded-xl border border-border bg-muted px-5 text-sm font-semibold text-foreground transition-colors hover:bg-surface"
                >
                  Email us
                </a>
              </div>
            </div>
          </section>
        </div>
      </PageShell>

      <SiteFooter />
    </div>
  );
}


