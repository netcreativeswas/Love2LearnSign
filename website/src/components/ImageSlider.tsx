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

export function ImageSlider() {
  const [currentIndex, setCurrentIndex] = useState(0);
  const [lightboxOpen, setLightboxOpen] = useState(false);
  const [lightboxIndex, setLightboxIndex] = useState(0);

  const goToPrevious = () => {
    setCurrentIndex((i) => (i - 1 + images.length) % images.length);
  };

  const goToNext = () => {
    setCurrentIndex((i) => (i + 1) % images.length);
  };

  const getOffset = (index: number) => {
    let diff = index - currentIndex;

    // wrap intelligent
    if (diff > images.length / 2) diff -= images.length;
    if (diff < -images.length / 2) diff += images.length;

    return diff;
  };

  return (
    <>
      <section className="mx-auto max-w-5xl px-4 py-12">
        <h2 className="mb-8 text-center text-2xl font-semibold">
          App Interface Preview
        </h2>

        <div className="relative overflow-hidden">
          <div className="relative h-[420px]">
            {images.map((img, index) => {
              const offset = getOffset(index);
              const isActive = offset === 0;

              return (
                <div
                  key={index}
                  className="absolute left-1/2 top-0 transition-[transform,opacity] duration-700 ease-out"
                  style={{
                    transform: `
                      translateX(${offset * STEP}px)
                      translateX(-50%)
                      scale(${isActive ? 1 : 0.8})
                    `,
                    opacity: isActive ? 1 : 0.5,
                    zIndex: isActive ? 10 : 5 - Math.abs(offset),
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
                        src={img.src}
                        alt={img.alt}
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

          {/* Arrows */}
          <button
            onClick={goToPrevious}
            className="absolute left-4 top-1/2 -translate-y-1/2 z-20 rounded-full bg-white/90 p-2 shadow"
          >
            ‹
          </button>

          <button
            onClick={goToNext}
            className="absolute right-4 top-1/2 -translate-y-1/2 z-20 rounded-full bg-white/90 p-2 shadow"
          >
            ›
          </button>

          {/* Dots */}
          <div className="mt-6 flex justify-center gap-2">
            {images.map((_, i) => (
              <button
                key={i}
                onClick={() => setCurrentIndex(i)}
                className={`h-2 rounded-full transition-all ${i === currentIndex
                    ? "w-8 bg-accent"
                    : "w-2 bg-muted-foreground/40"
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