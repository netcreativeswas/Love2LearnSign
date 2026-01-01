import { generateMetadata as genMeta } from "@/lib/metadata";
import { defaultLocale, getTranslations } from "@/lib/i18n";

const tr = getTranslations(defaultLocale);

export const metadata = genMeta({
  title: `${tr.deleteAccount.title} - ${tr.common.appName}`,
  description: tr.deleteAccount.description,
  path: "/delete-account",
  locale: "en",
});

export default function DeleteAccountLayout({ children }: { children: React.ReactNode }) {
  return children;
}


