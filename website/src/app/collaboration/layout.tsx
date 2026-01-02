import { generateMetadata as genMeta } from "@/lib/metadata";
import { defaultLocale, t as tr } from "@/lib/i18n";

export const metadata = genMeta({
  title: tr(defaultLocale, "collaboration.meta.title"),
  description: tr(defaultLocale, "collaboration.meta.description"),
  path: "/collaboration",
});

export default function CollaborationLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return children;
}


