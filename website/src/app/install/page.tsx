import type { Metadata } from "next";

import { SiteFooter } from "@/components/SiteFooter";
import { SiteHeader } from "@/components/SiteHeader";
import { PageShell } from "@/components/PageShell";
import { InstallClient } from "./InstallClient";

export const metadata: Metadata = {
  title: "Install",
  description: "Install link generator for co-brand tenants.",
  alternates: { canonical: "/install" },
  robots: {
    index: false,
    follow: false,
    nocache: true,
    googleBot: { index: false, follow: false, noimageindex: true },
  },
};

export default function InstallPage() {
  return (
    <div className="flex min-h-dvh flex-col bg-background text-foreground">
      <SiteHeader />
      <PageShell
        title="Install (Co-brand)"
        lede="Generate a QR code that selects a tenant in the Love2LearnSign app."
      >
        <InstallClient />
      </PageShell>
      <SiteFooter />
    </div>
  );
}


