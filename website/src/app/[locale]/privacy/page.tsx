"use client";

import { TranslationProvider } from "@/components/TranslationProvider";
import { PrivacyPolicyPage } from "@/components/PrivacyPolicyPage";
import { Locale, locales, defaultLocale } from "@/lib/i18n";

// Metadata is handled in the root layout
export default async function PrivacyPage({ params }: { params: Promise<{ locale: string }> }) {
  const { locale } = await params;
  const resolvedLocale = (locales.includes(locale as Locale) ? locale : defaultLocale) as Locale;

  return (
    <TranslationProvider locale={resolvedLocale}>
      <PrivacyPolicyPage locale={resolvedLocale} />
    </TranslationProvider>
  );
}


