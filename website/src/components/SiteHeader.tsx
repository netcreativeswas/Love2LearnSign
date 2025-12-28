import Image from "next/image";
import Link from "next/link";

import { siteConfig } from "@/lib/site-config";

const nav = [
  { href: "/", label: "Home" },
  { href: "/contact", label: "Contact Us" },
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
            width={50}
            height={50}
            priority
            className="rounded-full object-cover"
          />
          <div className="hidden sm:block">
            <div className="text-lg font-semibold leading-6 text-foreground">
              Love To Learn Sign
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


