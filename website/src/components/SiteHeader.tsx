"use client";

import { useState } from "react";
import Image from "next/image";
import Link from "next/link";

import { siteConfig } from "@/lib/site-config";

const nav = [
  { href: "/", label: "Home" },
  { href: "/contact", label: "Contact Us" },
  { href: "/donate", label: "Donate" },
] as const;

export function SiteHeader() {
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);

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
        <div className="fixed inset-0 z-50 sm:hidden">
          {/* Backdrop */}
          <div
            className="absolute inset-0 bg-black/50"
            onClick={() => setMobileMenuOpen(false)}
          />
          
          {/* Modal */}
          <div className="absolute right-0 top-0 h-full w-64 bg-surface border-l border-border shadow-lg">
            <div className="flex items-center justify-between p-4 border-b border-border">
              <div className="text-lg font-semibold text-foreground">Menu</div>
              <button
                onClick={() => setMobileMenuOpen(false)}
                className="rounded-lg p-2 text-foreground/90 transition-colors hover:bg-muted"
                aria-label="Close menu"
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
                    d="M6 18L18 6M6 6l12 12"
                  />
                </svg>
              </button>
            </div>
            
            <nav className="flex flex-col p-4">
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
            </nav>
          </div>
        </div>
      )}
    </header>
  );
}


