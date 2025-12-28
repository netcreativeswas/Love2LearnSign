import { generateMetadata as genMeta } from "@/lib/metadata";
import { defaultLocale, getTranslations } from "@/lib/i18n";

const locale = defaultLocale;
const translations = getTranslations(locale);

export const metadata = genMeta({
  title: `${translations.donate.title} - ${translations.common.appName}`,
  description: translations.donate.description,
  path: "/donate",
});

export default function DonateLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return children;
}

