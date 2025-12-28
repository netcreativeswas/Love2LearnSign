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
  const [lightboxOpen, setLightboxOpen] = useState(false);
  const [lightboxIndex, setLightboxIndex] = useState(0);

  // Patch : On utilise 3 clones pour une sécurité visuelle totale sur 5 slides visibles
  const CLONES = 3;
  const n = images.length;

  const slides = useMemo(() => {
    const head = images.slice(0, CLONES);
    const tail = images.slice(n - CLONES);
    return [...tail, ...images, ...head];
  }, [n]);

  const [trackIndex, setTrackIndex] = useState(CLONES);
  const [currentIndex, setCurrentIndex] = useState(0);
  const [enableTransition, setEnableTransition] = useState(true);
  const [direction, setDirection] = useState<Dir>("left");

  const isAnimatingRef = useRef(false);

  const ITEM_W = 225;
  const GAP = 16;
  const STEP = ITEM_W + GAP;

  // Le décalage pour centrer la slide active
  const CENTER_OFFSET = 0;

  const goToPrevious = () => {
    if (isAnimatingRef.current) return;
    isAnimatingRef.current = true;
    setDirection("right");
    setEnableTransition(true);
    setTrackIndex((t) => t - 1);
  };

  const goToNext = () => {
    if (isAnimatingRef.current) return;
    isAnimatingRef.current = true;
    setDirection("left");
    setEnableTransition(true);
    setTrackIndex((t) => t + 1);
  };

  const handleTransitionEnd = () => {
    isAnimatingRef.current = false;

    // Mise à jour de l'index réel pour la logique métier (ex: Lightbox)
    setCurrentIndex(((trackIndex - CLONES) % n + n) % n);

    // Correction de la boucle infinie (Téléportation silencieuse)
    if (trackIndex >= n + CLONES) {
      setEnableTransition(false);
      setTrackIndex(CLONES);
    } else if (trackIndex <= CLONES - 1) {
      setEnableTransition(false);
      setTrackIndex(n + CLONES - 1);
    }
  };

  // Réactiver la transition après la téléportation
  useEffect(() => {
    if (!enableTransition) {
      requestAnimationFrame(() => {
        setEnableTransition(true);
      });
    }
  }, [enableTransition]);

  // Calcul du décalage pour que la slide active (trackIndex) soit au milieu du conteneur
  const translateX = -(trackIndex * STEP);

  const getDepthStyle = (delta: number) => {
    const a = Math.abs(delta);
    if (a > 2)
      return {
        opacity: 0,
        transform: "scale(0.7)",
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
        opacity: 0.8,
        transform: "scale(0.85)",
        zIndex: 20,
      };
    // delta === 2
    return {
      opacity: 0.4,
      transform: "scale(0.75)",
      zIndex: 10,
    };
  };

  return (
    <>
      <section className="mx-auto max-w-7xl px-4 py-12 overflow-hidden">
        <h2 className="mb-12 text-center text-2xl font-semibold sm:text-3xl">
          App Interface Preview
        </h2>

        <div className="relative flex justify-center">
          <div
            className="flex items-center will-change-transform"
            style={{
              transform: `translate3d(${translateX}px, 0, 0)`,
              transition: enableTransition
                ? "transform 700ms cubic-bezier(0.22, 1, 0.36, 1)"
                : "none",
              paddingLeft: `calc(50% - ${ITEM_W / 2}px)`, // Pour centrer parfaitement
            }}
            onTransitionEnd={handleTransitionEnd}
          >
            {slides.map((img, vIndex) => {
              const delta = vIndex - trackIndex;
              const depth = getDepthStyle(delta);
              const realIndex = ((vIndex - CLONES) % n + n) % n;

              return (
                <div
                  key={vIndex}
                  className="flex-shrink-0 transition-all duration-700 ease-out"
                  style={{
                    width: ITEM_W,
                    marginRight: GAP,
                    ...depth
                  }}
                >
                  <button
                    className="w-full"
                    onClick={() => {
                      if (delta === 0) {
                        setLightboxIndex(realIndex);
                        setLightboxOpen(true);
                      } else {
                        delta > 0 ? goToNext() : goToPrevious();
                      }
                    }}
                  >
                    <div className="relative h-[450px] w-full">
                      <Image
                        src={img.src}
                        alt={img.alt}
                        fill
                        className="object-contain"
                        priority={delta === 0}
                        sizes="225px"
                      />
                    </div>
                  </button>
                </div>
              );
            })}
          </div>

          {/* Contrôles */}
          <button
            onClick={goToPrevious}
            className="absolute left-4 top-1/2 -translate-y-1/2 z-50 h-12 w-12 rounded-full bg-white/80 backdrop-blur shadow-lg flex items-center justify-center text-2xl hover:bg-white transition-colors"
          >
            ‹
          </button>

          <button
            onClick={goToNext}
            className="absolute right-4 top-1/2 -translate-y-1/2 z-50 h-12 w-12 rounded-full bg-white/80 backdrop-blur shadow-lg flex items-center justify-center text-2xl hover:bg-white transition-colors"
          >
            ›
          </button>
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