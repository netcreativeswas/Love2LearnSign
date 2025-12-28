"use client";

import { useMemo, useRef, useState } from "react";
import Image from "next/image";
import { Lightbox } from "./Lightbox";

const images = Array.from({ length: 11 }, (_, i) => ({
  src: `/slider-appUX/love2learnSign-app-UX-${String(i + 1).padStart(2, "0")}.png`,
  alt: `Love to Learn Sign UX ${i + 1}`,
}));

type Dir = "left" | "right";

export function ImageSlider() {
  const [currentIndex, setCurrentIndex] = useState(0);
  const [lightboxOpen, setLightboxOpen] = useState(false);
  const [lightboxIndex, setLightboxIndex] = useState(0);

  // ⬇️ Increased clones so 5-visible (±2) always has enough buffer for a seamless "infinite" loop
  const CLONES = 3;
  const n = images.length;

  const slides = useMemo(() => {
    const head = images.slice(0, CLONES);
    const tail = images.slice(n - CLONES);
    return [...tail, ...images, ...head];
  }, [n]);

  const [trackIndex, setTrackIndex] = useState(CLONES);
  const [enableTransition, setEnableTransition] = useState(true);
  const [direction, setDirection] = useState<Dir>("left");

  const isAnimatingRef = useRef(false);
  const settledTrackIndexRef = useRef(CLONES); // ✅ remember last "settled" index (after transition)

  // ⬇️ Shrink item width so 5 cards fit inside max-w-5xl and you actually SEE 5
  const ITEM_W = 186;
  const GAP = 16;
  const STEP = ITEM_W + GAP;

  // ✅ Center the 5-card viewport between the buttons
  const VISIBLE = 5;
  const VIEWPORT_W = ITEM_W * VISIBLE + GAP * (VISIBLE - 1); // 5 cards + 4 gaps

  const goToPrevious = () => {
    // ✅ removed click-blocking guard
    isAnimatingRef.current = true;
    setDirection("right");
    setEnableTransition(true);
    setTrackIndex((t) => t - 1);
  };

  const goToNext = () => {
    // ✅ removed click-blocking guard
    isAnimatingRef.current = true;
    setDirection("left");
    setEnableTransition(true);
    setTrackIndex((t) => t + 1);
  };

  const handleTransitionEnd = () => {
    isAnimatingRef.current = false;

    // ✅ update ACTIVE slide based on how many steps were actually moved
    const moved = trackIndex - settledTrackIndexRef.current; // + = next, - = prev
    if (moved !== 0) {
      setCurrentIndex((prev) => ((prev + (moved % n)) % n + n) % n);
    }

    // ✅ robust loop correction even if user clicked multiple times quickly
    const normalized = CLONES + ((((trackIndex - CLONES) % n) + n) % n);

    // if we are outside the "real" region, snap without transition
    if (trackIndex !== normalized) {
      setEnableTransition(false);
      setTrackIndex(normalized);
      settledTrackIndexRef.current = normalized;
      requestAnimationFrame(() => setEnableTransition(true));
      return;
    }

    // update last settled position
    settledTrackIndexRef.current = trackIndex;
  };

  // ✅ Correct centering: center the ACTIVE item in the viewport
  const CENTERING_OFFSET = (VIEWPORT_W - ITEM_W) / 2;
  const translateX = -trackIndex * STEP + CENTERING_OFFSET;

  const getDepthStyle = (delta: number) => {
    const a = Math.abs(delta);
    if (a > 2)
      return {
        opacity: 0,
        transform: "scale(0.75)",
        zIndex: 0,
        pointerEvents: "none" as const,
      };
    if (a === 0)
      return {
        opacity: 1,
        transform: "scale(1)",
        zIndex: 30,
      };
    if (a === 1)
      return {
        opacity: 0.85,
        transform: "scale(0.88)",
        zIndex: 20,
      };
    return {
      opacity: 0.65,
      transform: "scale(0.82)",
      zIndex: 10,
    };
  };

  return (
    <>
      <section className="mx-auto max-w-5xl px-4 py-12 sm:py-16">
        <h2 className="mb-8 text-center text-2xl font-semibold sm:text-3xl">
          App Interface Preview
        </h2>

        <div className="relative">
          {/* ✅ Centered viewport */}
          <div
            className="relative overflow-hidden mx-auto w-full"
            style={{ maxWidth: VIEWPORT_W }}
          >
            <div
              className="flex items-center gap-4 will-change-transform"
              style={{
                transform: `translate3d(${translateX}px,0,0)`,
                transition: enableTransition
                  ? "transform 800ms cubic-bezier(0.25,0.46,0.45,0.94)"
                  : "none",
              }}
              onTransitionEnd={handleTransitionEnd}
            >
              {slides.map((img, vIndex) => {
                const realIndex = (vIndex - CLONES + n) % n;
                const delta = vIndex - trackIndex;
                const depth = getDepthStyle(delta);

                // ⬇️ Preload visible range (center + 2 on each side) so the “last entering” slide
                // is NOT delayed the first time, and keeps carousel feeling truly infinite.
                const inView = Math.abs(delta) <= 2;

                return (
                  <div
                    key={vIndex}
                    className="flex-shrink-0 transition-[transform,opacity] duration-[800ms]"
                    style={depth}
                  >
                    <button
                      onClick={() =>
                        delta === 0
                          ? (setLightboxIndex(realIndex), setLightboxOpen(true))
                          : realIndex > currentIndex
                            ? goToNext()
                            : goToPrevious()
                      }
                    >
                      <div className="relative h-[400px] w-[186px]">
                        <Image
                          src={img.src}
                          alt={img.alt}
                          fill
                          className="object-contain"
                          priority={inView}
                        />
                      </div>
                    </button>
                  </div>
                );
              })}
            </div>

            {/* Buttons untouched */}
            <button
              onClick={goToPrevious}
              className="absolute left-3 top-1/2 -translate-y-1/2 z-40 h-11 w-11 rounded-full bg-accent text-accent-foreground shadow"
            >
              ‹
            </button>

            <button
              onClick={goToNext}
              className="absolute right-3 top-1/2 -translate-y-1/2 z-40 h-11 w-11 rounded-full bg-accent text-accent-foreground shadow"
            >
              ›
            </button>
          </div>
        </div>
      </section>

      {lightboxOpen && (
        <Lightbox
          images={images}
          currentIndex={lightboxIndex}
          onClose={() => setLightboxOpen(false)}
          onNavigate={setLightboxIndex}
        />
      )}
    </>
  );
}