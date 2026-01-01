import { generateMetadata as genMeta } from "@/lib/metadata";

export const metadata = genMeta({
  title: "Collaboration & White-label - Love to Learn Sign",
  description:
    "Partner with Love to Learn Sign to publish a sign language dictionary via co-branding or a fully white-labeled app. Learn how per-dictionary monetization can be organized (ads and subscriptions).",
  path: "/collaboration",
});

export default function CollaborationLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return children;
}


