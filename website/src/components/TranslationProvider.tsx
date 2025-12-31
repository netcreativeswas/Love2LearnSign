"use client";

import { createContext, useContext, ReactNode } from "react";
import { Locale, getTranslations } from "@/lib/i18n";

interface TranslationContextType {
  locale: Locale;
  translations: ReturnType<typeof getTranslations>;
  t: (key: string, params?: Record<string, string>) => string;
}

const TranslationContext = createContext<TranslationContextType | undefined>(
  undefined
);

export function TranslationProvider({
  locale,
  children,
}: {
  locale: Locale;
  children: ReactNode;
}) {
  const translations = getTranslations(locale);
  const isDev = process.env.NODE_ENV !== "production";

  const t = (key: string, params?: Record<string, string>): string => {
    const keys = key.split(".");
    let value: unknown = translations;

    for (const k of keys) {
      if (value && typeof value === "object" && k in value) {
        value = (value as Record<string, unknown>)[k];
      } else {
        if (isDev) {
        console.warn(`Translation key "${key}" not found for locale "${locale}"`);
        }
        return key;
      }
    }

    if (typeof value !== "string") {
      if (isDev) {
      console.warn(
        `Translation key "${key}" is not a string for locale "${locale}"`
      );
      }
      return key;
    }

    // Simple parameter replacement
    if (params) {
      return value.replace(/\{(\w+)\}/g, (match, paramKey) => {
        return params[paramKey] || match;
      });
    }

    return value;
  };

  return (
    <TranslationContext.Provider value={{ locale, translations, t }}>
      {children}
    </TranslationContext.Provider>
  );
}

export function useTranslations() {
  const context = useContext(TranslationContext);
  if (context === undefined) {
    throw new Error("useTranslations must be used within a TranslationProvider");
  }
  return context;
}

