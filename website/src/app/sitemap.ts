import { siteConfig } from "@/lib/site-config";

export default function sitemap() {
  const now = new Date();

  return [
    {
      url: `${siteConfig.url}/`,
      lastModified: now,
    },
    {
      url: `${siteConfig.url}/contact`,
      lastModified: now,
    },
    {
      url: `${siteConfig.url}/privacy`,
      lastModified: now,
    },
    {
      url: `${siteConfig.url}/delete-account`,
      lastModified: now,
    },
  ];
}


