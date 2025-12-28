import type { Metadata } from "next";
import { Geist, Geist_Mono } from "next/font/google";
import "./globals.css";
import { siteConfig } from "@/lib/site-config";

const geistSans = Geist({
  variable: "--font-geist-sans",
  subsets: ["latin"],
});

const geistMono = Geist_Mono({
  variable: "--font-geist-mono",
  subsets: ["latin"],
});

export const metadata: Metadata = {
  metadataBase: new URL(siteConfig.url),
  title: {
    default: siteConfig.appName,
    template: `%s · ${siteConfig.appName}`,
  },
  description:
    "Learn Bangla Sign Language with a modern dictionary, interactive quizzes, and spaced repetition flashcards. Build your vocabulary with short videos and practice at your own pace.",
  keywords: [
    "Bangla sign language",
    "Bengali sign language",
    "sign language learning",
    "deaf community",
    "sign language dictionary",
    "sign language app",
    "Bangladesh sign language",
    "BSL",
    "sign language flashcards",
    "sign language quizzes",
  ],
  applicationName: siteConfig.appName,
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
    canonical: "/",
  },
  openGraph: {
    type: "website",
    locale: "en_US",
    url: siteConfig.url,
    siteName: siteConfig.appName,
    title: siteConfig.appName,
    description:
      "Learn Bangla Sign Language with a modern dictionary, interactive quizzes, and spaced repetition flashcards. Build your vocabulary with short videos and practice at your own pace.",
    images: [
      {
        url: `${siteConfig.url}/og-image.png`,
        width: 1200,
        height: 630,
        alt: siteConfig.appName,
      },
    ],
  },
  twitter: {
    card: "summary_large_image",
    title: siteConfig.appName,
    description:
      "Learn Bangla Sign Language with a modern dictionary, interactive quizzes, and spaced repetition flashcards.",
    images: [`${siteConfig.url}/og-image.png`],
  },
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en">
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
