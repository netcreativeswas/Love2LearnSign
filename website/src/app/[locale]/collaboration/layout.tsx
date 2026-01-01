import { generateMetadata as genMeta } from "@/lib/metadata";
import { Locale, locales, defaultLocale } from "@/lib/i18n";

export async function generateMetadata({
  params,
}: {
  params: Promise<{ locale: string }>;
}) {
  const { locale } = await params;
  const resolvedLocale = (locales.includes(locale as Locale) ? locale : defaultLocale) as Locale;

  return genMeta({
    title: "Collaboration & White-label - Love to Learn Sign",
    description:
      "Partner with Love to Learn Sign to publish a sign language dictionary via co-branding or a fully white-labeled app. Learn how per-dictionary monetization can be organized (ads and subscriptions).",
    path: resolvedLocale === "en" ? "/collaboration" : `/${resolvedLocale}/collaboration`,
    locale: resolvedLocale,
  });
}

export default function CollaborationLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return children;
}


