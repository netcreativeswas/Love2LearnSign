import { Geist, Geist_Mono } from "next/font/google";
import { notFound } from "next/navigation";
import { Locale, locales, defaultLocale } from "@/lib/i18n";
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
  params: { locale: Locale };
}): Promise<Metadata> {
  const locale = params.locale || defaultLocale;
  
  return {
    metadataBase: new URL(siteConfig.url),
    title: {
      default: siteConfig.appName,
      template: `%s · ${siteConfig.appName}`,
    },
    alternates: {
      canonical: locale === defaultLocale ? "/" : `/${locale}`,
      languages: {
        en: "/",
        bn: "/bn",
      },
    },
    openGraph: {
      type: "website",
      locale: locale === "en" ? "en_US" : "bn_BD",
      alternateLocale: locale === "en" ? "bn_BD" : "en_US",
      url: locale === defaultLocale ? siteConfig.url : `${siteConfig.url}/${locale}`,
      siteName: siteConfig.appName,
    },
  };
}

export default function LocaleLayout({
  children,
  params,
}: {
  children: React.ReactNode;
  params: { locale: Locale };
}) {
  const { locale } = params;

  if (!locales.includes(locale)) {
    notFound();
  }

  return (
    <html lang={locale}>
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

