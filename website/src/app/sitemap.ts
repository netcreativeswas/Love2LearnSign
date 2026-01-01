import { siteConfig } from "@/lib/site-config";
import { MetadataRoute } from "next";

const pages = [
  { path: "/", priority: 1.0, changeFrequency: "weekly" as const },
  { path: "/contact", priority: 0.8, changeFrequency: "monthly" as const },
  { path: "/collaboration", priority: 0.75, changeFrequency: "monthly" as const },
  { path: "/donate", priority: 0.7, changeFrequency: "monthly" as const },
  { path: "/privacy", priority: 0.5, changeFrequency: "yearly" as const },
  { path: "/delete-account", priority: 0.5, changeFrequency: "yearly" as const },
];

function bnPath(path: string) {
  return path === "/" ? "/bn" : `/bn${path}`;
}

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
          bn: bnPath(page.path),
        },
      },
    });
  });

  // Add Bengali pages
  pages.forEach((page) => {
    sitemapEntries.push({
      url: `${siteConfig.url}${bnPath(page.path)}`,
      lastModified: now,
      changeFrequency: page.changeFrequency,
      priority: page.priority,
      alternates: {
        languages: {
          en: page.path,
          bn: bnPath(page.path),
        },
      },
    });
  });

  return sitemapEntries;
}


