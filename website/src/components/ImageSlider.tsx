"use client";

import { useState } from "react";
import Image from "next/image";
import { Lightbox } from "./Lightbox";

const images = Array.from({ length: 11 }, (_, i) => ({
  src: `/slider-appUX/love2learnSign-app-UX-${String(i + 1).padStart(2, "0")}.png`,
  alt: `Love to Learn Sign UX ${i + 1}`,
}));

const SLIDE_WIDTH = 225;
const SLIDE_GAP = 16;
const STEP = SLIDE_WIDTH + SLIDE_GAP;

// ⚠️ VERSION QUI ÉTAIT SMOOTH
const OFFSETS = [-3, -2, -1, 0, 1, 2, 3];

export function ImageSlider() {
  const [currentIndex, setCurrentIndex] = useState(0);
  const [lightboxOpen, setLightboxOpen] = useState(false);
  const [lightboxIndex, setLightboxIndex] = useState(0);

  const goTo = (dir: -1 | 1) => {
    setCurrentIndex((i) => (i + dir + images.length) % images.length);
  };

  const getIndex = (offset: number) => {
    let index = currentIndex + offset;
    if (index < 0) index += images.length;
    if (index >= images.length) index -= images.length;
    return index;
  };

  return (
    <>
      <section className="mx-auto max-w-5xl px-4 py-12">
        <h2 className="mb-8 text-center text-2xl font-semibold">
          App Interface Preview
        </h2>

        <div className="relative overflow-hidden">
          <div className="relative h-[420px]">
            {OFFSETS.map((offset) => {
              const index = getIndex(offset);
              const isActive = offset === 0;
              const isVisible = Math.abs(offset) <= 2;

              return (
                <div
                  key={`${currentIndex}-${offset}`}
                  className="absolute left-1/2 top-0 transition-[transform,opacity] duration-700 ease-[cubic-bezier(0.25,0.8,0.25,1)]"
                  style={{
                    transform: `
                      translateX(${offset * STEP}px)
                      translateX(-50%)
                      scale(${isActive ? 1 : isVisible ? 0.85 : 0.7})
                    `,
                    opacity: isVisible ? 1 : 0,
                    zIndex: isActive ? 10 : 6 - Math.abs(offset),
                    pointerEvents: isVisible ? "auto" : "none",
                    willChange: "transform, opacity",
                  }}
                >
                  <button
                    onClick={() =>
                      isActive
                        ? (setLightboxIndex(index), setLightboxOpen(true))
                        : setCurrentIndex(index)
                    }
                  >
                    <div className="relative h-[400px] w-[225px]">
                      <Image
                        src={images[index].src}
                        alt={images[index].alt}
                        fill
                        className="object-contain"
                        priority={isActive}
                      />
                    </div>
                  </button>
                </div>
              );
            })}
          </div>

          {/* ✅ PREV — ROND, COLOR SCHEME */}
          <button
            onClick={() => goTo(-1)}
            aria-label="Previous image"
            className="
              absolute left-4 top-1/2 z-30
              -translate-y-1/2
              w-11 h-11 rounded-full
              bg-surface text-foreground
              flex items-center justify-center
              shadow-md
              transition-colors
              hover:bg-accent hover:text-accent-foreground
              focus:outline-none
              focus:ring-2 focus:ring-accent/40
            "
          >
            <svg
              className="w-5 h-5"
              fill="none"
              stroke="currentColor"
              strokeWidth="2.5"
              viewBox="0 0 24 24"
            >
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                d="M15 19l-7-7 7-7"
              />
            </svg>
          </button>

          {/* ✅ NEXT — ROND, COLOR SCHEME */}
          <button
            onClick={() => goTo(1)}
            aria-label="Next image"
            className="
              absolute right-4 top-1/2 z-30
              -translate-y-1/2
              w-11 h-11 rounded-full
              bg-surface text-foreground
              flex items-center justify-center
              shadow-md
              transition-colors
              hover:bg-accent hover:text-accent-foreground
              focus:outline-none
              focus:ring-2 focus:ring-accent/40
            "
          >
            <svg
              className="w-5 h-5"
              fill="none"
              stroke="currentColor"
              strokeWidth="2.5"
              viewBox="0 0 24 24"
            >
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                d="M9 5l7 7-7 7"
              />
            </svg>
          </button>

          {/* Dots */}
          <div className="mt-6 flex justify-center gap-2">
            {images.map((_, i) => (
              <button
                key={i}
                onClick={() => setCurrentIndex(i)}
                className={`h-2 rounded-full transition-all ${i === currentIndex
                    ? "w-8 bg-accent"
                    : "w-2 bg-muted-foreground/40 hover:bg-muted-foreground/60"
                  }`}
              />
            ))}
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