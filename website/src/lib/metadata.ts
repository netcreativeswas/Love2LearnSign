import type { Metadata } from "next";
import { siteConfig } from "./site-config";

export interface PageMetadata {
  title: string;
  description: string;
  path?: string;
  image?: string;
  noIndex?: boolean;
}

export function generateMetadata({
  title,
  description,
  path = "",
  image = "/og-image.png",
  noIndex = false,
  locale = "en",
}: PageMetadata & { locale?: "en" | "bn" }): Metadata {
  const url = `${siteConfig.url}${path}`;
  const ogImage = image.startsWith("http") ? image : `${siteConfig.url}${image}`;
  const isBengali = locale === "bn" || path.startsWith("/bn");

  return {
    title,
    description,
    alternates: {
      canonical: url,
      languages: {
        en: path.replace("/bn", "") || "/",
        bn: path.startsWith("/bn") ? path : `/bn${path}`,
      },
    },
    openGraph: {
      type: "website",
      locale: isBengali ? "bn_BD" : "en_US",
      alternateLocale: isBengali ? "en_US" : "bn_BD",
      url,
      siteName: siteConfig.appName,
      title,
      description,
      images: [
        {
          url: ogImage,
          width: 1200,
          height: 630,
          alt: title,
        },
      ],
    },
    twitter: {
      card: "summary_large_image",
      title,
      description,
      images: [ogImage],
    },
    robots: noIndex
      ? {
          index: false,
          follow: false,
        }
      : {
          index: true,
          follow: true,
        },
  };
}

