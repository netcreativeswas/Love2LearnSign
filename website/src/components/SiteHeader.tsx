"use client";

import { useState, useEffect } from "react";
import { createPortal } from "react-dom";
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

  useEffect(() => {
    if (mobileMenuOpen) {
      document.body.style.overflow = "hidden";
    } else {
      document.body.style.overflow = "unset";
    }
    return () => {
      document.body.style.overflow = "unset";
    };
  }, [mobileMenuOpen]);

  const nav = [
    {
      href: getLocalizedPath("/", locale),
      label: t("common.home"),
      icon: (
        <svg
          width="18"
          height="18"
          viewBox="0 0 24 24"
          fill="none"
          stroke="currentColor"
          strokeWidth="2"
        >
          <path d="M3 10.5L12 3l9 7.5V21a1 1 0 0 1-1 1h-5v-7H9v7H4a1 1 0 0 1-1-1v-10.5z" />
        </svg>
      ),
    },
    {
      href: getLocalizedPath("/contact", locale),
      label: t("common.contact"),
      icon: (
        <svg
          width="18"
          height="18"
          viewBox="0 0 24 24"
          fill="none"
          stroke="currentColor"
          strokeWidth="2"
        >
          <path d="M4 4h16v16H4z" />
          <path d="M22 6l-10 7L2 6" />
        </svg>
      ),
    },
    {
      href: getLocalizedPath("/donate", locale),
      label: t("common.donate"),
      icon: (
        <svg
          width="18"
          height="18"
          viewBox="0 0 24 24"
          fill="none"
          stroke="currentColor"
          strokeWidth="2"
        >
          <path d="M12 21s-7-4.4-9.5-9A5.7 5.7 0 0 1 12 5.5 5.7 5.7 0 0 1 21.5 12C19 16.6 12 21 12 21z" />
        </svg>
      ),
    },
    // Dashboard Sign In is intentionally NOT localized and has no sign-up.
    {
      href: "/sign-in",
      label: t("common.signIn"),
      icon: (
        <svg
          width="18"
          height="18"
          viewBox="0 0 24 24"
          fill="none"
          stroke="currentColor"
          strokeWidth="2"
        >
          <path d="M15 3h4a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2h-4" />
          <path d="M10 17l5-5-5-5" />
          <path d="M15 12H3" />
        </svg>
      ),
    },
  ] as const;

  const modalContent = mobileMenuOpen ? (
    <div className="fixed inset-0 z-[9999] sm:hidden flex items-center justify-center min-h-screen">
      {/* Backdrop with blur - covers entire page */}
      <div
        className="fixed inset-0 bg-black/50 backdrop-blur-md"
        onClick={() => setMobileMenuOpen(false)}
      />
      
      {/* Modal - Centered */}
      <div className="relative bg-surface border border-border rounded-2xl shadow-2xl w-[90%] max-w-sm z-10">
        {/* Close button X in top right corner */}
        <button
          onClick={() => setMobileMenuOpen(false)}
          className="absolute -top-3 -right-3 rounded-full bg-surface border border-border p-2 text-foreground/90 transition-colors hover:bg-muted hover:text-foreground shadow-lg"
          aria-label={t("common.closeMenu")}
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
            <div className="text-xl font-semibold text-foreground text-center">{t("common.menu")}</div>
          </div>
          
          <nav className="flex flex-col gap-2">
            {nav.map((item) => (
              <Link
                key={item.href}
                href={item.href}
                onClick={() => setMobileMenuOpen(false)}
                className="rounded-lg px-4 py-3 text-base font-medium text-foreground/90 transition-colors hover:bg-muted hover:text-foreground"
              >
                <span className="flex items-center justify-center gap-2">
                  <span className="text-foreground/80">{item.icon}</span>
                  <span>{item.label}</span>
                </span>
              </Link>
            ))}
            <div className="mt-2 pt-2 border-t border-border flex justify-center">
              <LanguageSwitcher />
            </div>
          </nav>
        </div>
      </div>
    </div>
  ) : null;

  return (
    <header className="sticky top-0 z-50 border-b border-border/70 bg-surface/70 backdrop-blur">
      <div className="mx-auto flex max-w-5xl items-center justify-between gap-4 px-4 py-3">
        <Link
          href="/"
          className="group flex items-center gap-3 rounded-xl px-2 py-1 transition-colors hover:bg-muted"
          aria-label={t("common.homeAria", { appName: siteConfig.appName })}
        >
          <Image
            src="/brand/logo.png"
            alt={t("common.logoAlt", { appName: siteConfig.appName })}
            width={50}
            height={50}
            priority
            className="rounded-full object-cover"
          />
          <div className="text-lg font-semibold leading-6 text-foreground">
            {t("common.appName")}
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
              <span className="flex items-center gap-2">
                <span className="text-foreground/70">{item.icon}</span>
                <span>{item.label}</span>
              </span>
            </Link>
          ))}
          <LanguageSwitcher />
        </nav>

        {/* Mobile Hamburger Button */}
        <button
          onClick={() => setMobileMenuOpen(true)}
          className="sm:hidden rounded-lg p-2 text-foreground/90 transition-colors hover:bg-muted"
          aria-label={t("common.openMenu")}
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

      {/* Mobile Menu Modal - Rendered via Portal to body */}
      {typeof document !== "undefined" && modalContent
        ? createPortal(modalContent, document.body)
        : null}
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


