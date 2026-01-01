import type { NextConfig } from "next";

const securityHeaders = [
  // Clickjacking hardening (allows your own internal iframe usage, blocks other sites)
  {
    key: "Content-Security-Policy",
    value: "frame-ancestors 'self'; base-uri 'self'; object-src 'none'",
  },
  // Legacy clickjacking hardening (kept as defense-in-depth)
  { key: "X-Frame-Options", value: "SAMEORIGIN" },
  { key: "X-Content-Type-Options", value: "nosniff" },
  { key: "Referrer-Policy", value: "strict-origin-when-cross-origin" },
  {
    key: "Permissions-Policy",
    value: "camera=(), microphone=(), geolocation=(), payment=(), usb=()",
  },
  // Keep OAuth / popup flows working (vs strict `same-origin`)
  { key: "Cross-Origin-Opener-Policy", value: "same-origin-allow-popups" },
  // Safe if you serve everything over HTTPS (recommended for production)
  { key: "Strict-Transport-Security", value: "max-age=31536000" },
] as const;

const nextConfig: NextConfig = {
  async headers() {
    return [
      {
        source: "/:path*",
        headers: [...securityHeaders],
      },
    ];
  },
  async redirects() {
    return [
      // Canonical host: redirect non-www to www
      {
        source: "/:path*",
        has: [{ type: "host", value: "love2learnsign.com" }],
        destination: "https://www.love2learnsign.com/:path*",
        permanent: true,
      },
      {
        source: "/login",
        destination: "https://www.love2learnsign.com/sign-in",
        permanent: true,
      },
      {
        source: "/login/",
        destination: "https://www.love2learnsign.com/sign-in",
        permanent: true,
      },
      {
        source: "/log-in",
        destination: "https://www.love2learnsign.com/sign-in",
        permanent: true,
      },
      {
        source: "/log-in/",
        destination: "https://www.love2learnsign.com/sign-in",
        permanent: true,
      },
      {
        source: "/signin",
        destination: "https://www.love2learnsign.com/sign-in",
        permanent: true,
      },
      {
        source: "/signin/",
        destination: "https://www.love2learnsign.com/sign-in",
        permanent: true,
      },
    ];
  },
};

export default nextConfig;
