import { siteConfig } from "@/lib/site-config";

export default function robots() {
  return {
    rules: {
      userAgent: "*",
      allow: "/",
      // Prevent indexing/crawling of the embedded Flutter dashboard bundle.
      // (Actual /dashboard and /sign-in are handled via per-route `robots: noindex` metadata.)
      disallow: ["/dashboard-app", "/dashboard-app/"],
    },
    sitemap: `${siteConfig.url}/sitemap.xml`,
  };
}


