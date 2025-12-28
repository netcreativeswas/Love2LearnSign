import { generateMetadata as genMeta } from "@/lib/metadata";

export const metadata = genMeta({
  title: "Donate - Support Love to Learn Sign",
  description:
    "Support Love to Learn Sign development. Your donation helps improve the app and extend the dictionary to other sign languages. Help us make sign language learning accessible to everyone.",
  path: "/donate",
});

export default function DonateLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return children;
}

