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
  if (pathname.startsWith("/bn")) {
    return "bn";
  }
  return "en";
}

export function getPathWithoutLocale(pathname: string): string {
  if (pathname.startsWith("/bn")) {
    return pathname.replace("/bn", "") || "/";
  }
  return pathname;
}

export function getLocalizedPath(path: string, locale: Locale): string {
  const cleanPath = path.startsWith("/") ? path : `/${path}`;
  
  if (locale === "en") {
    return cleanPath;
  }
  
  return `/bn${cleanPath}`;
}

export function getTranslations(locale: Locale) {
  return translations[locale];
}

export function t(locale: Locale, key: string, params?: Record<string, string>): string {
  const keys = key.split(".");
  let value: any = translations[locale];
  
  for (const k of keys) {
    if (value && typeof value === "object" && k in value) {
      value = value[k];
    } else {
      console.warn(`Translation key "${key}" not found for locale "${locale}"`);
      return key;
    }
  }
  
  if (typeof value !== "string") {
    console.warn(`Translation key "${key}" is not a string for locale "${locale}"`);
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

