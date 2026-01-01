import { NextResponse } from "next/server";
import type { NextRequest } from "next/server";
import { locales } from "@/lib/i18n";

export function middleware(request: NextRequest) {
  const { pathname } = request.nextUrl;

  // Skip middleware for static files, API routes, and Next.js internals
  if (
    pathname.startsWith("/_next") ||
    pathname.startsWith("/api") ||
    pathname.startsWith("/favicon.ico") ||
    pathname.startsWith("/robots.txt") ||
    pathname.startsWith("/sitemap") ||
    pathname.startsWith("/manifest.json") ||
    pathname.match(/\.(ico|png|jpg|jpeg|svg|webp|gif|woff|woff2|ttf|eot)$/)
  ) {
    return NextResponse.next();
  }

  // English is the default locale and must NOT be prefixed.
  // Redirect any /en/* URLs to their canonical, non-prefixed equivalents.
  if (pathname === "/en" || pathname.startsWith("/en/")) {
    const url = request.nextUrl.clone();
    url.pathname = pathname.replace(/^\/en(?=\/|$)/, "") || "/";
    return NextResponse.redirect(url, 308);
  }

  // Check if pathname starts with a locale
  const pathnameHasLocale = locales.some(
    (locale) => pathname.startsWith(`/${locale}/`) || pathname === `/${locale}`
  );

  // If pathname already has a locale, continue
  if (pathnameHasLocale) {
    return NextResponse.next();
  }

  // For root path, serve as default locale (en) without redirect
  if (pathname === "/") {
    return NextResponse.next();
  }

  // For other paths without locale, continue (they will use default locale)
  return NextResponse.next();
}

export const config = {
  matcher: [
    /*
     * Match all request paths except for the ones starting with:
     * - api (API routes)
     * - _next/static (static files)
     * - _next/image (image optimization files)
     * - favicon.ico (favicon file)
     */
    "/((?!api|_next/static|_next/image|favicon.ico).*)",
  ],
};

