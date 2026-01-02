import { generateMetadata as genMeta } from "@/lib/metadata";
import { Locale, locales, defaultLocale, t as tr } from "@/lib/i18n";

export async function generateMetadata({
  params,
}: {
  params: Promise<{ locale: string }>;
}) {
  const { locale } = await params;
  const resolvedLocale = (locales.includes(locale as Locale) ? locale : defaultLocale) as Locale;

  return genMeta({
    title: tr(resolvedLocale, "collaboration.meta.title"),
    description: tr(resolvedLocale, "collaboration.meta.description"),
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


