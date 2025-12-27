import Image from "next/image";
import Link from "next/link";

import { siteConfig } from "@/lib/site-config";

const nav = [
  { href: "/", label: "Home" },
  { href: "/privacy", label: "Privacy" },
  { href: "/delete-account", label: "Delete account" },
  { href: "/contact", label: "Contact" },
] as const;

export function SiteHeader() {
  return (
    <header className="sticky top-0 z-50 border-b border-border/70 bg-surface/70 backdrop-blur">
      <div className="mx-auto flex max-w-5xl items-center justify-between gap-4 px-4 py-3">
        <Link
          href="/"
          className="group flex items-center gap-3 rounded-xl px-2 py-1 transition-colors hover:bg-muted"
          aria-label={`${siteConfig.appName} home`}
        >
          <Image
            src="/brand/logo.png"
            alt={`${siteConfig.appName} logo`}
            width={36}
            height={36}
            priority
            className="rounded-full object-cover"
          />
          <div className="hidden sm:block">
            <div className="text-sm font-semibold leading-5 text-foreground">
              {siteConfig.appName}
            </div>
            <div className="text-xs text-muted-foreground">
              {siteConfig.developerName}
            </div>
          </div>
        </Link>

        <nav className="flex items-center gap-1">
          {nav.map((item) => (
            <Link
              key={item.href}
              href={item.href}
              className="rounded-lg px-3 py-2 text-sm font-medium text-foreground/90 transition-colors hover:bg-muted hover:text-foreground"
            >
              {item.label}
            </Link>
          ))}
        </nav>
      </div>
    </header>
  );
}


