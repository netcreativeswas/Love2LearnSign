"use client";

import { useState } from "react";
import Image from "next/image";
import { Lightbox } from "./Lightbox";

const images = Array.from({ length: 11 }, (_, i) => ({
  src: `/slider-appUX/love2learnSign-app-UX-${String(i + 1).padStart(2, "0")}.png`,
  alt: `Love to Learn Sign UX ${i + 1}`,
}));

export function ImageSlider() {
  const [currentIndex, setCurrentIndex] = useState(0);
  const [lightboxOpen, setLightboxOpen] = useState(false);
  const [lightboxIndex, setLightboxIndex] = useState(0);

  const goToPrevious = () => {
    setCurrentIndex((prev) => (prev === 0 ? images.length - 1 : prev - 1));
  };

  const goToNext = () => {
    setCurrentIndex((prev) => (prev === images.length - 1 ? 0 : prev + 1));
  };

  const openLightbox = (index: number) => {
    setLightboxIndex(index);
    setLightboxOpen(true);
  };

  const closeLightbox = () => {
    setLightboxOpen(false);
  };

  // Get visible slides (current, previous, next)
  const getVisibleSlides = () => {
    const visible = [];
    for (let i = -2; i <= 2; i++) {
      let index = currentIndex + i;
      if (index < 0) index = images.length + index;
      if (index >= images.length) index = index - images.length;
      visible.push({ index, offset: i });
    }
    return visible;
  };

  return (
    <>
      <section className="mx-auto max-w-5xl px-4 py-12 sm:py-16">
        <h2 className="mb-8 text-center text-2xl font-semibold tracking-tight sm:text-3xl">
          App Interface Preview
        </h2>
        <div className="relative">
          {/* Carousel container */}
          <div className="flex items-center justify-center gap-4 overflow-hidden">
            {getVisibleSlides().map(({ index, offset }) => {
              const isActive = offset === 0;
              const scale = isActive ? 1 : 0.8;
              const opacity = isActive ? 1 : 0.65;
              const zIndex = isActive ? 10 : 5 - Math.abs(offset);

              return (
                <div
                  key={`${index}-${offset}`}
                  className="flex-shrink-0 transition-all duration-300 ease-in-out"
                  style={{
                    transform: `scale(${scale})`,
                    opacity: opacity,
                    zIndex: zIndex,
                  }}
                >
                  <button
                    onClick={() => {
                      if (offset !== 0) {
                        if (offset < 0) {
                          // Clicked on previous slide
                          setCurrentIndex(index);
                        } else {
                          // Clicked on next slide
                          setCurrentIndex(index);
                        }
                      } else {
                        openLightbox(index);
                      }
                    }}
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
                      />
                    </div>
                  </button>
                </div>
              );
            })}
          </div>

          {/* Navigation arrows */}
          <button
            onClick={goToPrevious}
            className="absolute left-4 top-1/2 -translate-y-1/2 z-20 rounded-full bg-surface/90 p-2 shadow-lg transition-colors hover:bg-surface"
            aria-label="Previous image"
          >
            <svg
              className="h-6 w-6 text-foreground"
              fill="none"
              stroke="currentColor"
              viewBox="0 0 24 24"
            >
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                strokeWidth={2}
                d="M15 19l-7-7 7-7"
              />
            </svg>
          </button>
          <button
            onClick={goToNext}
            className="absolute right-4 top-1/2 -translate-y-1/2 z-20 rounded-full bg-surface/90 p-2 shadow-lg transition-colors hover:bg-surface"
            aria-label="Next image"
          >
            <svg
              className="h-6 w-6 text-foreground"
              fill="none"
              stroke="currentColor"
              viewBox="0 0 24 24"
            >
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                strokeWidth={2}
                d="M9 5l7 7-7 7"
              />
            </svg>
          </button>

          {/* Dots indicator */}
          <div className="mt-6 flex justify-center gap-2">
            {images.map((_, index) => (
              <button
                key={index}
                onClick={() => setCurrentIndex(index)}
                className={`h-2 rounded-full transition-all ${
                  index === currentIndex
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
          onClose={closeLightbox}
          onNavigate={(index) => setLightboxIndex(index)}
        />
      )}
    </>
  );
}

