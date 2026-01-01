import { generateMetadata as genMeta } from "@/lib/metadata";
import { Locale, locales, defaultLocale, getTranslations, getLocalizedPath } from "@/lib/i18n";

export async function generateMetadata({
  params,
}: {
  params: Promise<{ locale: string }>;
}) {
  const { locale } = await params;
  const resolved = (locales.includes(locale as Locale) ? locale : defaultLocale) as Locale;
  const tr = getTranslations(resolved);

  return genMeta({
    title: `${tr.contact.title} - ${tr.common.appName}`,
    description: tr.contact.description,
    path: getLocalizedPath("/contact", resolved),
    locale: resolved,
  });
}

export default function ContactLocaleLayout({ children }: { children: React.ReactNode }) {
  return children;
}


