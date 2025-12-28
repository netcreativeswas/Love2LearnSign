import Link from "next/link";
import { SiteHeader } from "@/components/SiteHeader";
import { SiteFooter } from "@/components/SiteFooter";
import { siteConfig } from "@/lib/site-config";

export default function NotFound() {
  return (
    <div className="flex min-h-dvh flex-col bg-background text-foreground">
      <SiteHeader />
      <main className="flex-1">
        <div className="mx-auto max-w-5xl px-4 py-12 sm:py-16">
          <div className="text-center">
            <h1 className="text-6xl font-bold text-foreground sm:text-8xl">404</h1>
            <h2 className="mt-4 text-2xl font-semibold text-foreground sm:text-3xl">
              Page Not Found
            </h2>
            <p className="mt-4 text-lg text-muted-foreground">
              Sorry, we couldn't find the page you're looking for.
            </p>
            <div className="mt-8 flex flex-col items-center justify-center gap-4 sm:flex-row">
              <Link
                href="/"
                className="rounded-xl bg-accent px-6 py-3 text-sm font-semibold text-on-accent transition-colors hover:bg-accent/90"
              >
                Go Home
              </Link>
              <Link
                href="/contact"
                className="rounded-xl border border-border bg-surface px-6 py-3 text-sm font-semibold text-foreground transition-colors hover:bg-muted"
              >
                Contact Support
              </Link>
            </div>
            <div className="mt-12">
              <p className="text-sm font-semibold text-foreground">Popular Pages</p>
              <nav className="mt-4 flex flex-wrap justify-center gap-4">
                <Link
                  href="/"
                  className="text-sm text-muted-foreground hover:text-foreground hover:underline"
                >
                  Home
                </Link>
                <Link
                  href="/contact"
                  className="text-sm text-muted-foreground hover:text-foreground hover:underline"
                >
                  Contact
                </Link>
                <Link
                  href="/donate"
                  className="text-sm text-muted-foreground hover:text-foreground hover:underline"
                >
                  Donate
                </Link>
                <Link
                  href="/privacy"
                  className="text-sm text-muted-foreground hover:text-foreground hover:underline"
                >
                  Privacy Policy
                </Link>
              </nav>
            </div>
          </div>
        </div>
      </main>
      <SiteFooter />
    </div>
  );
}

