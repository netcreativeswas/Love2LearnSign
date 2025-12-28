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
const SLIDE_OFFSET = SLIDE_WIDTH + SLIDE_GAP;

export function ImageSlider() {
  const [currentIndex, setCurrentIndex] = useState(0);
  const [lightboxOpen, setLightboxOpen] = useState(false);
  const [lightboxIndex, setLightboxIndex] = useState(0);

  const goToPrevious = () => {
    setCurrentIndex((prev) =>
      prev === 0 ? images.length - 1 : prev - 1
    );
  };

  const goToNext = () => {
    setCurrentIndex((prev) =>
      prev === images.length - 1 ? 0 : prev + 1
    );
  };

  const openLightbox = (index: number) => {
    setLightboxIndex(index);
    setLightboxOpen(true);
  };

  const getVisibleSlides = () => {
    const visible = [];
    for (let i = -2; i <= 2; i++) {
      let index = currentIndex + i;
      if (index < 0) index += images.length;
      if (index >= images.length) index -= images.length;
      visible.push({ index, offset: i });
    }
    return visible;
  };

  return (
    <>
      <section className="mx-auto max-w-5xl px-4 py-12 sm:py-16">
        <h2 className="mb-8 text-center text-2xl font-semibold sm:text-3xl">
          App Interface Preview
        </h2>

        <div className="relative">
          {/* Slider */}
          <div className="flex items-center justify-center overflow-hidden">
            {getVisibleSlides().map(({ index, offset }) => {
              const isActive = offset === 0;

              return (
                <div
                  key={index} // 🔥 clé STABLE
                  className="flex-shrink-0 transition-[transform,opacity] duration-700 ease-out"
                  style={{
                    transform: `
                      translateX(${offset * SLIDE_OFFSET}px)
                      scale(${isActive ? 1 : 0.8})
                    `,
                    opacity: isActive ? 1 : 0.6,
                    zIndex: isActive ? 10 : 5 - Math.abs(offset),
                    willChange: "transform, opacity",
                  }}
                >
                  <button
                    onClick={() =>
                      isActive ? openLightbox(index) : setCurrentIndex(index)
                    }
                    className="relative block"
                    aria-label={
                      isActive
                        ? "Open image in lightbox"
                        : `Go to image ${index + 1}`
                    }
                  >
                    <div className="relative aspect-[9/16] h-[400px] w-[225px]">
                      <Image
                        src={images[index].src}
                        alt={images[index].alt}
                        fill
                        className="object-contain"
                        sizes="225px"
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
            className="absolute left-4 top-1/2 z-20 -translate-y-1/2 rounded-full bg-white/90 p-2 shadow-lg hover:bg-white"
            aria-label="Previous image"
          >
            <svg
              className="h-6 w-6"
              fill="none"
              stroke="currentColor"
              viewBox="0 0 24 24"
            >
              <path strokeWidth={2} strokeLinecap="round" d="M15 19l-7-7 7-7" />
            </svg>
          </button>

          <button
            onClick={goToNext}
            className="absolute right-4 top-1/2 z-20 -translate-y-1/2 rounded-full bg-white/90 p-2 shadow-lg hover:bg-white"
            aria-label="Next image"
          >
            <svg
              className="h-6 w-6"
              fill="none"
              stroke="currentColor"
              viewBox="0 0 24 24"
            >
              <path strokeWidth={2} strokeLinecap="round" d="M9 5l7 7-7 7" />
            </svg>
          </button>

          {/* Dots */}
          <div className="mt-6 flex justify-center gap-2">
            {images.map((_, index) => (
              <button
                key={index}
                onClick={() => setCurrentIndex(index)}
                className={`h-2 rounded-full transition-all ${index === currentIndex
                    ? "w-8 bg-accent"
                    : "w-2 bg-muted-foreground/30 hover:bg-muted-foreground/50"
                  }`}
                aria-label={`Go to image ${index + 1}`}
              />
            ))}
          </div>
        </div>
      </section>

      {/* Lightbox */}
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