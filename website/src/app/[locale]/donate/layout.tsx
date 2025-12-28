import { generateMetadata as genMeta } from "@/lib/metadata";
import { Locale, getTranslations } from "@/lib/i18n";

export async function generateMetadata({
  params,
}: {
  params: { locale: Locale };
}) {
  const locale = params.locale;
  const translations = getTranslations(locale);

  return genMeta({
    title: `${translations.donate.title} - ${translations.common.appName}`,
    description: translations.donate.description,
    path: locale === "en" ? "/donate" : `/${locale}/donate`,
  });
}

export default function DonateLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return children;
}

