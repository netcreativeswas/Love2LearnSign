import { generateMetadata as genMeta } from "@/lib/metadata";
import { Locale, getTranslations } from "@/lib/i18n";

import { locales, defaultLocale } from "@/lib/i18n";

export async function generateMetadata({
  params,
}: {
  params: Promise<{ locale: string }>;
}) {
  const { locale } = await params;
  const resolvedLocale = (locales.includes(locale as Locale) ? locale : defaultLocale) as Locale;
  const translations = getTranslations(resolvedLocale);

  return genMeta({
    title: `${translations.donate.title} - ${translations.common.appName}`,
    description: translations.donate.description,
    path: resolvedLocale === "en" ? "/donate" : `/${resolvedLocale}/donate`,
  });
}

export default function DonateLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return children;
}

