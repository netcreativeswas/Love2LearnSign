import { generateMetadata as genMeta } from "@/lib/metadata";
import { defaultLocale, getTranslations } from "@/lib/i18n";

const tr = getTranslations(defaultLocale);

export const metadata = genMeta({
  title: `${tr.contact.title} - ${tr.common.appName}`,
  description: tr.contact.description,
  path: "/contact",
  locale: "en",
});

export default function ContactLayout({ children }: { children: React.ReactNode }) {
  return children;
}


