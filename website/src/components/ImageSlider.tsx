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

  /* ===============================
     CLONES (loop propre)
  =============================== */
  const CLONES = 2;
  const n = images.length;

  const slides = useMemo(() => {
    const head = images.slice(0, CLONES);
    const tail = images.slice(n - CLONES);
    return [...tail, ...images, ...head];
  }, [n]);

  const [trackIndex, setTrackIndex] = useState(CLONES);
  const [enableTransition, setEnableTransition] = useState(true);
  const [direction, setDirection] = useState<Dir>("left");
  const animating = useRef(false);

  /* ===============================
     DIMENSIONS
  =============================== */
  const ITEM_W = 225;
  const GAP = 16;
  const STEP = ITEM_W + GAP;
  const CENTER_OFFSET = CLONES * STEP;

  /* ===============================
     NAVIGATION
  =============================== */
  const goPrev = () => {
    if (animating.current) return;
    animating.current = true;
    setDirection("right");
    setEnableTransition(true);
    setTrackIndex((i) => i - 1);
  };

  const goNext = () => {
    if (animating.current) return;
    animating.current = true;
    setDirection("left");
    setEnableTransition(true);
    setTrackIndex((i) => i + 1);
  };

  /* ===============================
     TRANSITION END
  =============================== */
  const onTransitionEnd = () => {
    animating.current = false;

    // update active AFTER movement
    setCurrentIndex((prev) =>
      direction === "left"
        ? (prev + 1) % n
        : (prev - 1 + n) % n
    );

    // loop correction (invisible)
    if (trackIndex >= n + CLONES) {
      setEnableTransition(false);
      setTrackIndex(CLONES);
      requestAnimationFrame(() => setEnableTransition(true));
    }

    if (trackIndex <= CLONES - 1) {
      setEnableTransition(false);
      setTrackIndex(n + CLONES - 1);
      requestAnimationFrame(() => setEnableTransition(true));
    }
  };

  /* ===============================
     POSITION
  =============================== */
  const translateX = -(trackIndex * STEP) + CENTER_OFFSET;

  /* ===============================
     DEPTH (STRICT 5 SLIDES)
  =============================== */
  const getDepthStyle = (delta: number) => {
    const a = Math.abs(delta);

    // ❌ OUT — removed from render completely
    if (a > 2) {
      return { display: "none" };
    }

    if (a === 0) {
      return {
        opacity: 1,
        transform: "scale(1)",
        zIndex: 30,
        pointerEvents: "auto" as const,
      };
    }

    if (a === 1) {
      return {
        opacity: 0.85,
        transform: "scale(0.88)",
        zIndex: 20,
        pointerEvents: "auto" as const,
      };
    }

    // a === 2
    return {
      opacity: 0.65,
      transform: "scale(0.82)",
      zIndex: 10,
      pointerEvents: "auto" as const,
    };
  };

  /* ===============================
     RENDER
  =============================== */
  return (
    <>
      <section className="mx-auto max-w-5xl px-4 py-12 sm:py-16">
        <h2 className="mb-8 text-center text-2xl font-semibold sm:text-3xl">
          App Interface Preview
        </h2>

        <div className="relative">
          <div className="relative overflow-hidden">
            {/* TRACK */}
            <div
              className="flex items-center gap-4 will-change-transform"
              style={{
                transform: `translate3d(${translateX}px,0,0)`,
                transition: enableTransition
                  ? "transform 800ms cubic-bezier(0.25,0.46,0.45,0.94)"
                  : "none",
              }}
              onTransitionEnd={onTransitionEnd}
            >
              {slides.map((img, vIndex) => {
                const realIndex = (vIndex - CLONES + n) % n;
                const delta = vIndex - trackIndex;
                const depth = getDepthStyle(delta);

                return (
                  <div
                    key={vIndex}
                    className="flex-shrink-0 transition-[transform,opacity] duration-[800ms] ease-[cubic-bezier(0.25,0.46,0.45,0.94)]"
                    style={{
                      ...depth,
                      willChange: "transform, opacity",
                      backfaceVisibility: "hidden",
                    }}
                  >
                    <button
                      onClick={() =>
                        delta === 0
                          ? (setLightboxIndex(realIndex),
                            setLightboxOpen(true))
                          : delta > 0
                            ? goNext()
                            : goPrev()
                      }
                    >
                      <div className="relative h-[400px] w-[225px]">
                        <Image
                          src={img.src}
                          alt={img.alt}
                          fill
                          className="object-contain"
                          priority={delta === 0}
                        />
                      </div>
                    </button>
                  </div>
                );
              })}
            </div>

            {/* PREV */}
            <button
              onClick={goPrev}
              className="absolute left-3 top-1/2 -translate-y-1/2 z-40 h-11 w-11 rounded-full bg-accent text-accent-foreground shadow"
              aria-label="Previous"
            >
              ‹
            </button>

            {/* NEXT */}
            <button
              onClick={goNext}
              className="absolute right-3 top-1/2 -translate-y-1/2 z-40 h-11 w-11 rounded-full bg-accent text-accent-foreground shadow"
              aria-label="Next"
            >
              ›
            </button>
          </div>
        </div>
      </section>

      {/* LIGHTBOX */}
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