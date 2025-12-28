"use client";

import { useEffect, useMemo, useRef, useState } from "react";
import Image from "next/image";
import { Lightbox } from "./Lightbox";

const images = Array.from({ length: 11 }, (_, i) => ({
  src: `/slider-appUX/love2learnSign-app-UX-${String(i + 1).padStart(2, "0")}.png`,
  alt: `Love to Learn Sign UX ${i + 1}`,
}));

type Dir = "left" | "right";

export function ImageSlider() {
  const [currentIndex, setCurrentIndex] = useState(0); // index réel (0..n-1)
  const [lightboxOpen, setLightboxOpen] = useState(false);
  const [lightboxIndex, setLightboxIndex] = useState(0);

  // --- Slider technique "clones" pour un loop propre (sans passer par derrière)
  const CLONES = 2; // pour afficher 5 slides (2 à gauche, centre, 2 à droite)
  const n = images.length;

  const slides = useMemo(() => {
    const head = images.slice(0, CLONES);
    const tail = images.slice(n - CLONES);
    return [...tail, ...images, ...head]; // taille = n + 2*CLONES
  }, [n]);

  // index sur la liste "slides" (avec clones)
  const [trackIndex, setTrackIndex] = useState(CLONES); // commence sur la 1ère vraie slide
  const [enableTransition, setEnableTransition] = useState(true);
  const [direction, setDirection] = useState<Dir>("left");

  const isAnimatingRef = useRef(false);

  // dimensions (doivent matcher tes classes h/w + gap)
  const ITEM_W = 225; // w-[225px]
  const GAP = 16; // gap-4 => 1rem = 16px
  const STEP = ITEM_W + GAP;

  // centre du viewport: on veut que trackIndex soit au centre des 5 visibles (offset = 2)
  const CENTER_OFFSET = CLONES * STEP;

  const goToPrevious = () => {
    if (isAnimatingRef.current) return;
    isAnimatingRef.current = true;
    setDirection("right");
    setEnableTransition(true);
    setTrackIndex((t) => t - 1);
    setCurrentIndex((prev) => (prev === 0 ? n - 1 : prev - 1));
  };

  const goToNext = () => {
    if (isAnimatingRef.current) return;
    isAnimatingRef.current = true;
    setDirection("left");
    setEnableTransition(true);
    setTrackIndex((t) => t + 1);
    setCurrentIndex((prev) => (prev === n - 1 ? 0 : prev + 1));
  };

  const openLightbox = (index: number) => {
    setLightboxIndex(index);
    setLightboxOpen(true);
  };

  const closeLightbox = () => setLightboxOpen(false);

  // Jump “invisible” après transition si on est sur un clone
  const handleTransitionEnd = () => {
    // libère le verrou d’animation
    isAnimatingRef.current = false;

    // si on a dépassé à droite (sur un clone du début)
    if (trackIndex >= n + CLONES) {
      // on coupe la transition et on se téléporte au vrai index équivalent
      setEnableTransition(false);
      setTrackIndex(CLONES); // revient sur la 1ère vraie slide
      // réactive la transition au prochain tick
      requestAnimationFrame(() => setEnableTransition(true));
      return;
    }

    // si on a dépassé à gauche (sur un clone de fin)
    if (trackIndex <= CLONES - 1) {
      setEnableTransition(false);
      setTrackIndex(n + CLONES - 1); // dernière vraie slide
      requestAnimationFrame(() => setEnableTransition(true));
      return;
    }
  };

  // Quand on clique un dot: on va au plus court chemin (et on reste smooth)
  const goToIndex = (target: number) => {
    if (target === currentIndex) return;
    if (isAnimatingRef.current) return;

    // calc shortest direction
    const forward = (target - currentIndex + n) % n;
    const backward = (currentIndex - target + n) % n;

    isAnimatingRef.current = true;

    if (forward <= backward) {
      setDirection("left");
      setEnableTransition(true);
      setTrackIndex((t) => t + forward);
    } else {
      setDirection("right");
      setEnableTransition(true);
      setTrackIndex((t) => t - backward);
    }

    setCurrentIndex(target);
  };

  // translateX en px: on centre trackIndex au milieu
  const translateX = -(trackIndex * STEP) + CENTER_OFFSET;

  // Styles de profondeur (scale/opacity/zIndex) basés sur la position relative
  const getDepthStyle = (delta: number) => {
    const a = Math.abs(delta);

    // hors des 5 visibles => on masque (mais on laisse pour continuité)
    if (a > 2) {
      return {
        opacity: 0,
        transform: `scale(0.75)`,
        zIndex: 0,
        pointerEvents: "none" as const,
      };
    }

    // 5 visibles
    if (a === 0) {
      return {
        opacity: 1,
        transform: `scale(1)`,
        zIndex: 30,
        pointerEvents: "auto" as const,
      };
    }
    if (a === 1) {
      return {
        opacity: 0.85,
        transform: `scale(0.88)`,
        zIndex: 20,
        pointerEvents: "auto" as const,
      };
    }
    // a === 2
    return {
      opacity: 0.65,
      transform: `scale(0.82)`,
      zIndex: 10,
      pointerEvents: "auto" as const,
    };
  };

  // Optionnel: si images.length change (rare)
  useEffect(() => {
    setTrackIndex(CLONES + currentIndex);
  }, [CLONES, currentIndex]);

  return (
    <>
      <section className="mx-auto max-w-5xl px-4 py-12 sm:py-16">
        <h2 className="mb-8 text-center text-2xl font-semibold tracking-tight sm:text-3xl">
          App Interface Preview
        </h2>

        <div className="relative">
          {/* Viewport */}
          <div className="relative overflow-hidden">
            {/* Track (smooth restauré ici) */}
            <div
              className="flex items-center gap-4 will-change-transform"
              style={{
                transform: `translate3d(${translateX}px, 0, 0)`,
                transition: enableTransition
                  ? "transform 800ms cubic-bezier(0.25,0.46,0.45,0.94)"
                  : "none",
              }}
              onTransitionEnd={handleTransitionEnd}
            >
              {slides.map((img, vIndex) => {
                // vIndex -> index réel correspondant
                const realIndex = (vIndex - CLONES + n) % n;

                // delta = distance (en “steps”) par rapport au centre (trackIndex)
                const delta = vIndex - trackIndex;
                const depth = getDepthStyle(delta);

                return (
                  <div
                    key={`v-${vIndex}-${img.src}`}
                    className="flex-shrink-0 transition-[transform,opacity] duration-[800ms] ease-[cubic-bezier(0.25,0.46,0.45,0.94)]"
                    style={{
                      ...depth,
                      willChange: "transform, opacity",
                      backfaceVisibility: "hidden",
                      WebkitBackfaceVisibility: "hidden",
                      transformOrigin: "center center",
                    }}
                  >
                    <button
                      onClick={() => {
                        // si on clique la slide centrale -> lightbox
                        if (delta === 0) openLightbox(realIndex);
                        else goToIndex(realIndex);
                      }}
                      className="relative block"
                      aria-label={
                        delta === 0
                          ? "Open image in lightbox"
                          : `Go to image ${realIndex + 1}`
                      }
                    >
                      <div className="relative aspect-[9/16] h-[400px] w-[225px]">
                        <Image
                          src={img.src}
                          alt={img.alt}
                          fill
                          className="object-contain"
                          sizes="225px"
                          priority={delta === 0}
                        />
                      </div>
                    </button>
                  </div>
                );
              })}
            </div>

            {/* Navigation arrows (ronds + lisibles) */}
            <button
              onClick={goToPrevious}
              className="absolute left-3 top-1/2 -translate-y-1/2 z-40 grid h-11 w-11 place-items-center rounded-full bg-accent/90 text-accent-foreground shadow-lg ring-1 ring-foreground/10 backdrop-blur transition hover:bg-accent focus:outline-none focus:ring-2 focus:ring-accent"
              aria-label="Previous image"
            >
              <svg
                className="h-6 w-6"
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
              className="absolute right-3 top-1/2 -translate-y-1/2 z-40 grid h-11 w-11 place-items-center rounded-full bg-accent/90 text-accent-foreground shadow-lg ring-1 ring-foreground/10 backdrop-blur transition hover:bg-accent focus:outline-none focus:ring-2 focus:ring-accent"
              aria-label="Next image"
            >
              <svg
                className="h-6 w-6"
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
          </div>

          {/* Dots indicator */}
          <div className="mt-6 flex justify-center gap-2">
            {images.map((_, index) => (
              <button
                key={index}
                onClick={() => goToIndex(index)}
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
          onClose={closeLightbox}
          onNavigate={(index) => setLightboxIndex(index)}
        />
      )}
    </>
  );
}