import Image from "next/image";
import Link from "next/link";

import { siteConfig } from "@/lib/site-config";

export function SiteFooter() {
  return (
    <footer className="mt-auto border-t border-border/70 bg-surface">
      <div className="mx-auto max-w-5xl px-4 py-10">
        {/* Top row */}
        <div className="mb-8 grid gap-8 sm:grid-cols-2">
          {/* Left side - Logo and description */}
          <div className="flex flex-col gap-3">
            <div className="flex items-center gap-3">
              <Image
                src="/brand/logo.png"
                alt={`${siteConfig.appName} logo`}
                width={48}
                height={48}
                className="rounded-full object-cover"
              />
              <div className="text-lg font-semibold text-foreground">
                Love to Learn Sign
              </div>
            </div>
            <p className="max-w-md text-sm leading-6 text-muted-foreground">
              Learn Bengali Sign Language with a modern dictionary, interactive
              quizzes, and spaced repetition flashcards. Build your vocabulary
              with short videos and practice at your own pace.
            </p>
          </div>

          {/* Right side - Support */}
          <div className="flex flex-col justify-start">
            <div className="text-sm font-semibold text-foreground">Support</div>
            <div className="mt-2 text-sm text-muted-foreground">
              <a
                className="font-medium text-foreground hover:underline"
                href={`mailto:${siteConfig.supportEmail}`}
              >
                {siteConfig.supportEmail}
              </a>
            </div>
          </div>
        </div>

        {/* Bottom row - Centered links */}
        <div className="flex flex-col items-center gap-4 border-t border-border/50 pt-8">
          <div className="flex flex-wrap items-center justify-center gap-x-6 gap-y-2 text-sm">
            <Link
              className="text-foreground/90 hover:underline"
              href="/privacy"
            >
              Privacy
            </Link>
            <Link
              className="text-foreground/90 hover:underline"
              href="/delete-account"
            >
              Delete Account
            </Link>
            <Link
              className="text-foreground/90 hover:underline"
              href="/contact"
            >
              Contact
            </Link>
            <a
              className="text-foreground/90 hover:underline"
              href={siteConfig.playStoreUrl}
              target="_blank"
              rel="noreferrer"
            >
              Google Play
            </a>
          </div>
          <div className="text-xs text-muted-foreground">
            Made by{" "}
            <a
              href="https://netcreative-swas.net"
              target="_blank"
              rel="noreferrer"
              className="font-medium text-foreground hover:underline"
            >
              NetCreative
            </a>
          </div>
        </div>
      </div>
    </footer>
  );
}


