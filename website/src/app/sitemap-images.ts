import { siteConfig } from "@/lib/site-config";
import { MetadataRoute } from "next";

// Note: Next.js sitemap doesn't support image metadata directly
// This sitemap lists the homepage with all slider images as URLs
// For proper image sitemap, consider using a separate XML file or
// adding image metadata to the main sitemap entries
export default function sitemapImages(): MetadataRoute.Sitemap {
  return [
    {
      url: `${siteConfig.url}/`,
      lastModified: new Date(),
      changeFrequency: "weekly",
      priority: 1.0,
    },
    // Individual image URLs for better indexing
    ...Array.from({ length: 11 }, (_, i) => ({
      url: `${siteConfig.url}/slider-appUX/love2learnSign-app-UX-${String(i + 1).padStart(2, "0")}.png`,
      lastModified: new Date(),
      changeFrequency: "monthly" as const,
      priority: 0.3,
    })),
  ];
}

