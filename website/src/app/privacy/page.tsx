"use client";

import { TranslationProvider } from "@/components/TranslationProvider";
import { PrivacyPolicyPage } from "@/components/PrivacyPolicyPage";
import { defaultLocale } from "@/lib/i18n";

const locale = defaultLocale;

// Metadata is handled in the root layout
export default function PrivacyPage() {
  return (
    <TranslationProvider locale={locale}>
      <PrivacyPolicyPage locale={locale} />
    </TranslationProvider>
  );
}


