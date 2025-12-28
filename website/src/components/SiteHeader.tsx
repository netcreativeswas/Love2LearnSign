"use client";

import { useState } from "react";
import Image from "next/image";
import Link from "next/link";
import { usePathname } from "next/navigation";
import { siteConfig } from "@/lib/site-config";
import { TranslationProvider, useTranslations } from "./TranslationProvider";
import { LanguageSwitcher } from "./LanguageSwitcher";
import { Locale, getLocaleFromPath, getLocalizedPath } from "@/lib/i18n";

function SiteHeaderContent() {
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);
  const pathname = usePathname();
  const locale = getLocaleFromPath(pathname);
  const { t } = useTranslations();

  const nav = [
    { href: getLocalizedPath("/", locale), label: t("common.home") },
    { href: getLocalizedPath("/contact", locale), label: t("common.contact") },
    { href: getLocalizedPath("/donate", locale), label: t("common.donate") },
  ] as const;

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
          <div className="text-lg font-semibold leading-6 text-foreground">
            Love To Learn Sign
          </div>
        </Link>

        {/* Desktop Navigation */}
        <nav className="hidden sm:flex items-center gap-1">
          {nav.map((item) => (
            <Link
              key={item.href}
              href={item.href}
              className="rounded-lg px-3 py-2 text-sm font-medium text-foreground/90 transition-colors hover:bg-muted hover:text-foreground"
            >
              {item.label}
            </Link>
          ))}
          <LanguageSwitcher />
        </nav>

        {/* Mobile Hamburger Button */}
        <button
          onClick={() => setMobileMenuOpen(true)}
          className="sm:hidden rounded-lg p-2 text-foreground/90 transition-colors hover:bg-muted"
          aria-label="Open menu"
        >
          <svg
            className="h-6 w-6"
            fill="none"
            stroke="currentColor"
            viewBox="0 0 24 24"
          >
            <path
              strokeLinecap="round"
              strokeLinejoin="round"
              strokeWidth={2}
              d="M4 6h16M4 12h16M4 18h16"
            />
          </svg>
        </button>
      </div>

      {/* Mobile Menu Modal */}
      {mobileMenuOpen && (
        <div className="fixed inset-0 z-50 sm:hidden flex items-center justify-center min-h-screen">
          {/* Backdrop with blur */}
          <div
            className="absolute inset-0 bg-black/50 backdrop-blur-sm"
            onClick={() => setMobileMenuOpen(false)}
          />
          
          {/* Modal - Centered */}
          <div className="relative bg-surface border border-border rounded-2xl shadow-2xl w-[90%] max-w-sm">
            {/* Close button X in top right corner */}
            <button
              onClick={() => setMobileMenuOpen(false)}
              className="absolute -top-3 -right-3 rounded-full bg-surface border border-border p-2 text-foreground/90 transition-colors hover:bg-muted hover:text-foreground shadow-lg"
              aria-label="Close menu"
            >
              <svg
                className="h-5 w-5"
                fill="none"
                stroke="currentColor"
                viewBox="0 0 24 24"
              >
                <path
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  strokeWidth={2}
                  d="M6 18L18 6M6 6l12 12"
                />
              </svg>
            </button>
            
            <div className="p-6">
              <div className="mb-6">
                <div className="text-xl font-semibold text-foreground">{t("common.menu")}</div>
              </div>
              
              <nav className="flex flex-col gap-2">
                {nav.map((item) => (
                  <Link
                    key={item.href}
                    href={item.href}
                    onClick={() => setMobileMenuOpen(false)}
                    className="rounded-lg px-4 py-3 text-base font-medium text-foreground/90 transition-colors hover:bg-muted hover:text-foreground"
                  >
                    {item.label}
                  </Link>
                ))}
                <div className="mt-2 pt-2 border-t border-border">
                  <LanguageSwitcher />
                </div>
              </nav>
            </div>
          </div>
        </div>
      )}
    </header>
  );
}

export function SiteHeader() {
  const pathname = usePathname();
  const locale = getLocaleFromPath(pathname);

  return (
    <TranslationProvider locale={locale}>
      <SiteHeaderContent />
    </TranslationProvider>
  );
}


