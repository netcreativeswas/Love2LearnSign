import { CollaborationPage } from "@/components/CollaborationPage";
import { Locale, locales, defaultLocale } from "@/lib/i18n";

export default async function Collaboration({
  params,
}: {
  params: Promise<{ locale: string }>;
}) {
  const { locale } = await params;
  const resolvedLocale = (locales.includes(locale as Locale) ? locale : defaultLocale) as Locale;
  return <CollaborationPage locale={resolvedLocale} />;
}


