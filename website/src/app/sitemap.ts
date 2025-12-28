import { siteConfig } from "@/lib/site-config";
import { MetadataRoute } from "next";

const pages = [
  { path: "/", priority: 1.0, changeFrequency: "weekly" as const },
  { path: "/contact", priority: 0.8, changeFrequency: "monthly" as const },
  { path: "/donate", priority: 0.7, changeFrequency: "monthly" as const },
  { path: "/privacy", priority: 0.5, changeFrequency: "yearly" as const },
  { path: "/delete-account", priority: 0.5, changeFrequency: "yearly" as const },
];

export default function sitemap(): MetadataRoute.Sitemap {
  const now = new Date();

  const sitemapEntries: MetadataRoute.Sitemap = [];

  // Add English pages (default locale)
  pages.forEach((page) => {
    sitemapEntries.push({
      url: `${siteConfig.url}${page.path}`,
      lastModified: now,
      changeFrequency: page.changeFrequency,
      priority: page.priority,
      alternates: {
        languages: {
          en: page.path,
          bn: `/bn${page.path}`,
        },
      },
    });
  });

  // Add Bengali pages
  pages.forEach((page) => {
    sitemapEntries.push({
      url: `${siteConfig.url}/bn${page.path}`,
      lastModified: now,
      changeFrequency: page.changeFrequency,
      priority: page.priority,
      alternates: {
        languages: {
          en: page.path,
          bn: `/bn${page.path}`,
        },
      },
    });
  });

  return sitemapEntries;
}


