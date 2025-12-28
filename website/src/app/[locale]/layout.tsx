import { Geist, Geist_Mono } from "next/font/google";
import { notFound } from "next/navigation";
import { Locale, locales, defaultLocale, getTranslations } from "@/lib/i18n";
import { siteConfig } from "@/lib/site-config";
import type { Metadata } from "next";
import "../globals.css";

const geistSans = Geist({
  variable: "--font-geist-sans",
  subsets: ["latin"],
});

const geistMono = Geist_Mono({
  variable: "--font-geist-mono",
  subsets: ["latin"],
});

export function generateStaticParams() {
  return locales.map((locale) => ({ locale }));
}

export async function generateMetadata({
  params,
}: {
  params: Promise<{ locale: string }>;
}): Promise<Metadata> {
  const { locale } = await params;
  const resolvedLocale = (locales.includes(locale as Locale) ? locale : defaultLocale) as Locale;
  const translations = getTranslations(resolvedLocale);
  
  return {
    metadataBase: new URL(siteConfig.url),
    title: {
      default: translations.common.appName,
      template: `%s · ${translations.common.appName}`,
    },
    description: resolvedLocale === "en" 
      ? translations.home.description 
      : translations.home.description,
    icons: {
      icon: [
        { url: "/favicon.ico", sizes: "32x32", type: "image/x-icon" },
        { url: "/icon.png", sizes: "any" },
        { url: "/icon-192x192.png", sizes: "192x192", type: "image/png" },
        { url: "/icon-512x512.png", sizes: "512x512", type: "image/png" },
      ],
      apple: [
        { url: "/apple-icon.png", sizes: "180x180", type: "image/png" },
      ],
    },
    alternates: {
      canonical: resolvedLocale === defaultLocale ? "/" : `/${resolvedLocale}`,
      languages: {
        en: "/",
        bn: "/bn",
      },
    },
    openGraph: {
      type: "website",
      locale: resolvedLocale === "en" ? "en_US" : "bn_BD",
      alternateLocale: resolvedLocale === "en" ? "bn_BD" : "en_US",
      url: resolvedLocale === defaultLocale ? siteConfig.url : `${siteConfig.url}/${resolvedLocale}`,
      siteName: translations.common.appName,
      title: translations.common.appName,
      description: translations.home.description,
    },
    twitter: {
      card: "summary_large_image",
      title: translations.common.appName,
      description: translations.home.description,
    },
  };
}

export default async function LocaleLayout({
  children,
  params,
}: {
  children: React.ReactNode;
  params: Promise<{ locale: string }>;
}) {
  const { locale } = await params;
  const resolvedLocale = locale as Locale;

  if (!locales.includes(resolvedLocale)) {
    notFound();
  }

  return (
    <html lang={resolvedLocale}>
      <head>
        <link rel="manifest" href="/manifest.json" />
      </head>
      <body
        className={`${geistSans.variable} ${geistMono.variable} flex min-h-dvh flex-col bg-background text-foreground antialiased`}
      >
        {children}
      </body>
    </html>
  );
}

