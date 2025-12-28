"use client";

import { usePathname } from "next/navigation";
import Link from "next/link";
import { Locale, getLocaleFromPath, getPathWithoutLocale, getLocalizedPath } from "@/lib/i18n";

export function LanguageSwitcher() {
  const pathname = usePathname();
  const currentLocale = getLocaleFromPath(pathname);
  const pathWithoutLocale = getPathWithoutLocale(pathname);

  const switchLocale = currentLocale === "en" ? "bn" : "en";
  const switchPath = getLocalizedPath(pathWithoutLocale, switchLocale);
  const switchLabel = currentLocale === "en" ? "বাংলা" : "English";

  return (
    <Link
      href={switchPath}
      className="rounded-lg px-3 py-2 text-sm font-medium text-foreground/90 transition-colors hover:bg-muted hover:text-foreground"
      aria-label={`Switch to ${switchLocale}`}
    >
      {switchLabel}
    </Link>
  );
}

