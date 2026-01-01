import enTranslations from "@/locales/en.json";
import bnTranslations from "@/locales/bn.json";

export type Locale = "en" | "bn";

export const locales: Locale[] = ["en", "bn"];
export const defaultLocale: Locale = "en";

export const translations = {
  en: enTranslations,
  bn: bnTranslations,
} as const;

export function getLocaleFromPath(pathname: string): Locale {
  if (pathname === "/bn" || pathname.startsWith("/bn/")) {
    return "bn";
  }
  if (pathname === "/en" || pathname.startsWith("/en/")) {
    return "en";
  }
  return "en";
}

export function getPathWithoutLocale(pathname: string): string {
  if (pathname === "/bn" || pathname.startsWith("/bn/")) {
    return pathname.replace(/^\/bn(?=\/|$)/, "") || "/";
  }
  if (pathname === "/en" || pathname.startsWith("/en/")) {
    return pathname.replace(/^\/en(?=\/|$)/, "") || "/";
  }
  return pathname;
}

export function getLocalizedPath(path: string, locale: Locale): string {
  const withLeadingSlash = path.startsWith("/") ? path : `/${path}`;
  const cleanPath = getPathWithoutLocale(withLeadingSlash);

  if (locale === "en") return cleanPath;

  // Bengali is the only prefixed locale.
  return cleanPath === "/" ? "/bn" : `/bn${cleanPath}`;
}

export function getTranslations(locale: Locale) {
  return translations[locale];
}

export function t(locale: Locale, key: string, params?: Record<string, string>): string {
  const isDev = process.env.NODE_ENV !== "production";
  const keys = key.split(".");
  let value: unknown = translations[locale];
  
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
    console.warn(`Translation key "${key}" is not a string for locale "${locale}"`);
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
}

