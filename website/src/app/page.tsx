import Image from "next/image";
import Link from "next/link";

import { SiteFooter } from "@/components/SiteFooter";
import { SiteHeader } from "@/components/SiteHeader";
import { ImageSlider } from "@/components/ImageSlider";
import { siteConfig } from "@/lib/site-config";

export default function Home() {
  return (
    <div className="flex min-h-dvh flex-col bg-background text-foreground">
      <SiteHeader />

      <main className="flex-1">
        <div className="mx-auto max-w-5xl px-4 py-12 sm:py-16">
        <div className="grid items-center gap-10 lg:grid-cols-2">
          <div className="space-y-6">
            <div className="inline-flex items-center gap-2 rounded-full border border-border bg-surface px-4 py-2 text-sm text-muted-foreground">
              <span className="h-2 w-2 rounded-full bg-accent" />
              Learn. Practice. Remember.
            </div>

            <h1 className="text-balance text-4xl font-semibold tracking-tight sm:text-5xl">
              Learn Bangladesh Language
            </h1>

            <p className="max-w-prose text-lg leading-8 text-muted-foreground">
              Discover Bengali Sign Language through short videos and a simple learning flow.
              Practice with a dictionary, flashcards, quizzes, favorites, and spaced repetition to build vocabulary step by step.
              Available in English and Bengali.
            </p>

            <div className="flex flex-col gap-3 sm:flex-row sm:items-center">
              <a
                href={siteConfig.playStoreUrl}
                target="_blank"
                rel="noreferrer"
                className="inline-flex items-center justify-center transition-opacity hover:opacity-90"
              >
                <Image
                  src="/icons/google-play-download.png"
                  alt="Get it on Google Play"
                  width={180}
                  height={60}
                  className="h-auto w-auto"
                />
              </a>
              <Link
                href="/contact"
                className="inline-flex h-12 items-center justify-center rounded-xl border border-border bg-surface px-5 text-sm font-semibold text-foreground transition-colors hover:bg-muted"
              >
                Contact support
              </Link>
            </div>
          </div>

          <div className="relative">
            <div className="absolute -inset-6 -z-10 rounded-3xl bg-accent/10 blur-2xl" />
            <div className="rounded-3xl border border-border bg-surface p-8 shadow-sm">
              <div className="flex items-center gap-4">
                <Image
                  src="/brand/logo.png"
                  alt={`${siteConfig.appName} logo`}
                  width={56}
                  height={56}
                  priority
                  className="rounded-full"
                />
                <div>
                  <div className="text-lg font-semibold">{siteConfig.appName}</div>
                  <div className="text-sm text-muted-foreground">
                    By {siteConfig.developerName}
                  </div>
                </div>
              </div>

              <div className="mt-6 grid gap-3 sm:grid-cols-2">
                <div className="rounded-2xl bg-muted p-4">
                  <div className="text-sm font-semibold">Dictionary</div>
                  <div className="mt-1 text-sm text-muted-foreground">
                    Find signs fast and save favorites.
                  </div>
                </div>
                <div className="rounded-2xl bg-muted p-4">
                  <div className="text-sm font-semibold">Quizzes</div>
                  <div className="mt-1 text-sm text-muted-foreground">
                    Practice with timed, category-based quizzes.
                  </div>
                </div>
                <div className="rounded-2xl bg-muted p-4">
                  <div className="text-sm font-semibold">Flashcards</div>
                  <div className="mt-1 text-sm text-muted-foreground">
                    Spaced repetition to remember words.
                  </div>
                </div>
                <div className="rounded-2xl bg-muted p-4">
                  <div className="text-sm font-semibold">Offline</div>
                  <div className="mt-1 text-sm text-muted-foreground">
                    Cached videos for smoother playback.
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>

        <ImageSlider />
        </div>
      </main>

      <SiteFooter />
    </div>
  );
}
