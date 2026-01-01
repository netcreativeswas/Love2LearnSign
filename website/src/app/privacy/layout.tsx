import { generateMetadata as genMeta } from "@/lib/metadata";
import { defaultLocale, getTranslations } from "@/lib/i18n";

const tr = getTranslations(defaultLocale);

export const metadata = genMeta({
  title: `${tr.privacy.title} - ${tr.common.appName}`,
  description: tr.privacy.description,
  path: "/privacy",
  locale: "en",
});

export default function PrivacyLayout({ children }: { children: React.ReactNode }) {
  return children;
}


