import Link from "next/link";
import { SiteHeader } from "@/components/SiteHeader";
import { SiteFooter } from "@/components/SiteFooter";
import { PageShell } from "@/components/PageShell";
import { SectionCard } from "@/components/SectionCard";
import { StructuredData, BreadcrumbList } from "@/components/StructuredData";
import { siteConfig } from "@/lib/site-config";
import { Locale, getLocalizedPath, t as tr } from "@/lib/i18n";

type FaqItem = {
  question: string;
  answer: string;
};

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

  const pageTitle = tr(locale, "collaboration.pageTitle");
  const pageDescription = tr(locale, "collaboration.pageDescription");

  const pageUrl = `${siteConfig.url}${collaborationPath}`;
  const homeUrl = `${siteConfig.url}${getLocalizedPath("/", locale)}`;

  const faq: FaqItem[] = [
    { question: tr(locale, "collaboration.faqQ1"), answer: tr(locale, "collaboration.faqA1") },
    { question: tr(locale, "collaboration.faqQ2"), answer: tr(locale, "collaboration.faqA2") },
    { question: tr(locale, "collaboration.faqQ3"), answer: tr(locale, "collaboration.faqA3") },
    { question: tr(locale, "collaboration.faqQ4"), answer: tr(locale, "collaboration.faqA4") },
    { question: tr(locale, "collaboration.faqQ5"), answer: tr(locale, "collaboration.faqA5") },
    { question: tr(locale, "collaboration.faqQ6"), answer: tr(locale, "collaboration.faqA6") },
    { question: tr(locale, "collaboration.faqQ7"), answer: tr(locale, "collaboration.faqA7") },
    { question: tr(locale, "collaboration.faqQ8"), answer: tr(locale, "collaboration.faqA8") },
  ];

  return (
    <div className="flex min-h-dvh flex-col bg-background text-foreground">
      <BreadcrumbList
        items={[
          { name: tr(locale, "common.home"), url: homeUrl },
          { name: tr(locale, "collaboration.breadcrumb"), url: pageUrl },
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
                  {tr(locale, "collaboration.heroTitle")}
                </h2>
                <p className="text-sm leading-7 text-muted-foreground">
                  {tr(locale, "collaboration.heroP1")}
                </p>
                <p className="text-sm leading-7 text-muted-foreground">
                  {tr(locale, "collaboration.heroP2")}
                </p>
                <div className="flex flex-col gap-3 sm:flex-row sm:items-center">
                  <Link
                    href={contactPath}
                    className="inline-flex h-12 items-center justify-center rounded-xl border border-border bg-surface px-5 text-sm font-semibold text-foreground transition-colors hover:bg-muted"
                  >
                    {tr(locale, "collaboration.ctaContact")}
                  </Link>
                  <a
                    href={`mailto:${siteConfig.supportEmail}`}
                    className="text-sm font-semibold text-foreground hover:underline"
                  >
                    {tr(locale, "collaboration.ctaEmail", { email: siteConfig.supportEmail })}
                  </a>
                </div>
              </div>

              <div className="relative">
                <div className="absolute -inset-6 -z-10 rounded-3xl bg-accent/10 blur-2xl" />
                <div className="rounded-3xl border border-border bg-muted p-6 sm:p-8">
                  <div className="text-sm font-semibold">{tr(locale, "collaboration.whatYouGetTitle")}</div>
                  <ul className="mt-3 space-y-2 text-sm text-muted-foreground">
                    <li>{tr(locale, "collaboration.whatYouGet1")}</li>
                    <li>{tr(locale, "collaboration.whatYouGet2")}</li>
                    <li>{tr(locale, "collaboration.whatYouGet3")}</li>
                    <li>{tr(locale, "collaboration.whatYouGet4")}</li>
                  </ul>
                  <div className="mt-6 rounded-2xl bg-surface p-4">
                    <div className="text-sm font-semibold">{tr(locale, "collaboration.importantTitle")}</div>
                    <p className="mt-1 text-sm text-muted-foreground">
                      {tr(locale, "collaboration.importantBody")}
                    </p>
                  </div>
                </div>
              </div>
            </div>
          </section>

          <SectionCard title={tr(locale, "collaboration.twoWaysTitle")}>
            <div className="grid gap-4 lg:grid-cols-2">
              <div className="rounded-2xl border border-border bg-muted p-5">
                <div className="text-base font-semibold text-foreground">{tr(locale, "collaboration.coBrandingTitle")}</div>
                <p className="mt-2 text-sm text-muted-foreground">
                  {tr(locale, "collaboration.coBrandingBody")}
                </p>
              </div>
              <div className="rounded-2xl border border-border bg-muted p-5">
                <div className="text-base font-semibold text-foreground">{tr(locale, "collaboration.whiteLabelTitle")}</div>
                <p className="mt-2 text-sm text-muted-foreground">
                  {tr(locale, "collaboration.whiteLabelBody")}
                </p>
              </div>
            </div>
          </SectionCard>

          <SectionCard title={tr(locale, "collaboration.prosConsTitle")}>
            <div className="grid gap-6 lg:grid-cols-2">
              <div className="rounded-2xl border border-border bg-surface p-5">
                <div className="text-base font-semibold">{tr(locale, "collaboration.coBrandingTitle")}</div>
                <div className="mt-4 grid gap-4 sm:grid-cols-2">
                  <div>
                    <div className="text-sm font-semibold">{tr(locale, "collaboration.pros")}</div>
                    <ul className="mt-2 list-inside list-disc space-y-1 text-sm text-muted-foreground">
                      <li>{tr(locale, "collaboration.coBrandingPros1")}</li>
                      <li>{tr(locale, "collaboration.coBrandingPros2")}</li>
                      <li>{tr(locale, "collaboration.coBrandingPros3")}</li>
                    </ul>
                  </div>
                  <div>
                    <div className="text-sm font-semibold">{tr(locale, "collaboration.cons")}</div>
                    <ul className="mt-2 list-inside list-disc space-y-1 text-sm text-muted-foreground">
                      <li>{tr(locale, "collaboration.coBrandingCons1")}</li>
                      <li>{tr(locale, "collaboration.coBrandingCons2")}</li>
                      <li>{tr(locale, "collaboration.coBrandingCons3")}</li>
                    </ul>
                  </div>
                </div>
              </div>

              <div className="rounded-2xl border border-border bg-surface p-5">
                <div className="text-base font-semibold">{tr(locale, "collaboration.whiteLabelTitle")}</div>
                <div className="mt-4 grid gap-4 sm:grid-cols-2">
                  <div>
                    <div className="text-sm font-semibold">{tr(locale, "collaboration.pros")}</div>
                    <ul className="mt-2 list-inside list-disc space-y-1 text-sm text-muted-foreground">
                      <li>{tr(locale, "collaboration.whiteLabelPros1")}</li>
                      <li>{tr(locale, "collaboration.whiteLabelPros2")}</li>
                      <li>{tr(locale, "collaboration.whiteLabelPros3")}</li>
                    </ul>
                  </div>
                  <div>
                    <div className="text-sm font-semibold">{tr(locale, "collaboration.cons")}</div>
                    <ul className="mt-2 list-inside list-disc space-y-1 text-sm text-muted-foreground">
                      <li>{tr(locale, "collaboration.whiteLabelCons1")}</li>
                      <li>{tr(locale, "collaboration.whiteLabelCons2")}</li>
                      <li>{tr(locale, "collaboration.whiteLabelCons3")}</li>
                    </ul>
                  </div>
                </div>
              </div>
            </div>
          </SectionCard>

          <SectionCard title={tr(locale, "collaboration.platformWorksTitle")}>
            <div className="grid gap-4 lg:grid-cols-2">
              <div className="rounded-2xl bg-muted p-5">
                <div className="text-sm font-semibold">{tr(locale, "collaboration.perDictionaryTitle")}</div>
                <p className="mt-2 text-sm text-muted-foreground">
                  {tr(locale, "collaboration.perDictionaryBody")}
                </p>
              </div>
              <div className="rounded-2xl bg-muted p-5">
                <div className="text-sm font-semibold">{tr(locale, "collaboration.revenueTitle")}</div>
                <p className="mt-2 text-sm text-muted-foreground">
                  {tr(locale, "collaboration.revenueBody")}
                </p>
              </div>
            </div>
          </SectionCard>

          <SectionCard title={tr(locale, "collaboration.faqTitle")}>
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
                <h2 className="text-xl font-semibold tracking-tight">{tr(locale, "collaboration.closingTitle")}</h2>
                <p className="mt-2 text-sm leading-7 text-muted-foreground">
                  {tr(locale, "collaboration.closingBody")}
                </p>
              </div>
              <div className="flex flex-col gap-3 sm:flex-row lg:flex-col">
                <Link
                  href={contactPath}
                  className="inline-flex h-12 items-center justify-center rounded-xl border border-border bg-surface px-5 text-sm font-semibold text-foreground transition-colors hover:bg-muted"
                >
                  {tr(locale, "collaboration.closingContact")}
                </Link>
                <a
                  href={`mailto:${siteConfig.supportEmail}`}
                  className="inline-flex h-12 items-center justify-center rounded-xl border border-border bg-muted px-5 text-sm font-semibold text-foreground transition-colors hover:bg-surface"
                >
                  {tr(locale, "collaboration.closingEmail")}
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


