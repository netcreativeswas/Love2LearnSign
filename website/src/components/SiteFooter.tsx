import Link from "next/link";

import { siteConfig } from "@/lib/site-config";

export function SiteFooter() {
  return (
    <footer className="border-t border-border/70 bg-surface">
      <div className="mx-auto flex max-w-5xl flex-col gap-4 px-4 py-10 sm:flex-row sm:items-center sm:justify-between">
        <div className="space-y-1">
          <div className="text-sm font-semibold text-foreground">
            {siteConfig.appName}
          </div>
          <div className="text-sm text-muted-foreground">
            Support:{" "}
            <a
              className="font-medium text-foreground hover:underline"
              href={`mailto:${siteConfig.supportEmail}`}
            >
              {siteConfig.supportEmail}
            </a>
          </div>
        </div>

        <div className="flex flex-wrap items-center gap-x-4 gap-y-2 text-sm">
          <Link className="text-foreground/90 hover:underline" href="/privacy">
            Privacy Policy
          </Link>
          <Link
            className="text-foreground/90 hover:underline"
            href="/delete-account"
          >
            Delete Account
          </Link>
          <Link className="text-foreground/90 hover:underline" href="/contact">
            Contact
          </Link>
          <a
            className="text-foreground/90 hover:underline"
            href={siteConfig.playStoreUrl}
            target="_blank"
            rel="noreferrer"
          >
            Google Play
          </a>
        </div>
      </div>
    </footer>
  );
}


