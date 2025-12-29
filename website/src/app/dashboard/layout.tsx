import type { Metadata } from "next";

export const metadata: Metadata = {
  title: "Dashboard",
  description: "Love to Learn Sign dashboard.",
  alternates: {
    canonical: "/dashboard",
  },
  // Authenticated area — should not be indexed.
  robots: {
    index: false,
    follow: false,
    nocache: true,
    googleBot: {
      index: false,
      follow: false,
      noimageindex: true,
    },
  },
};

export default function DashboardLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return children;
}


