"use client";

import { useRef } from "react";
import Image from "next/image";
import { motion, useScroll, useTransform, useReducedMotion } from "motion/react";
import { screenshotPhotos } from "@/lib/images";
import { Eyebrow } from "../primitives/Eyebrow";
import { RevealOnView } from "../motion/RevealOnView";
import { NutrientPill } from "../primitives/NutrientPill";

export function Screenshots() {
  const reduce = useReducedMotion();
  const ref = useRef<HTMLDivElement>(null);
  const { scrollYProgress } = useScroll({ target: ref, offset: ["start end", "end start"] });

  // Each phone moves at a slightly different speed
  const y0 = useTransform(scrollYProgress, [0, 1], reduce ? [0, 0] : [80, -80]);
  const y1 = useTransform(scrollYProgress, [0, 1], reduce ? [0, 0] : [40, -40]);
  const y2 = useTransform(scrollYProgress, [0, 1], reduce ? [0, 0] : [120, -120]);

  return (
    <section ref={ref} className="relative py-28 md:py-36 overflow-hidden">
      <div className="mx-auto max-w-7xl px-6">
        <RevealOnView>
          <div className="max-w-2xl mb-16 text-center mx-auto">
            <Eyebrow>In the app</Eyebrow>
            <h2 className="display-sans text-[clamp(36px,5vw,64px)] mt-5 leading-[1.0] text-center">
              Calm interface. Honest numbers.
            </h2>
          </div>
        </RevealOnView>

        <div className="grid grid-cols-1 md:grid-cols-3 gap-6 md:gap-8 max-w-5xl mx-auto">
          <motion.div style={{ y: y0 }} className="md:translate-y-8">
            <PhoneFrame photo={screenshotPhotos[0].url} alt={screenshotPhotos[0].alt} caption="Today" rotate={-4} />
          </motion.div>
          <motion.div style={{ y: y1 }}>
            <PhoneFrame photo={screenshotPhotos[1].url} alt={screenshotPhotos[1].alt} caption="Vitamin breakdown" rotate={0} variant="vitamins" />
          </motion.div>
          <motion.div style={{ y: y2 }} className="md:translate-y-12">
            <PhoneFrame photo={screenshotPhotos[2].url} alt={screenshotPhotos[2].alt} caption="Weekly trends" rotate={4} />
          </motion.div>
        </div>
      </div>
    </section>
  );
}

function PhoneFrame({
  photo, alt, caption, rotate, variant,
}: {
  photo: string;
  alt: string;
  caption: string;
  rotate: number;
  variant?: "vitamins";
}) {
  return (
    <div
      className="relative aspect-[9/19] rounded-[36px] border border-[var(--color-border)] bg-[var(--color-surface)] overflow-hidden shadow-[0_40px_100px_-40px_rgba(19,26,22,0.25)] mx-auto max-w-[280px]"
      style={{ transform: `rotate(${rotate}deg)` }}
    >
      <Image src={photo} alt={alt} fill sizes="280px" className="object-cover" />
      <div className="absolute inset-0 bg-gradient-to-t from-[rgba(19,26,22,0.85)] via-transparent to-transparent" />
      {variant === "vitamins" && (
        <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 flex flex-wrap gap-2 justify-center max-w-[200px]">
          {(["A","C","D","E","K","B12","Fe","Mg","Ca"] as const).map((c) => (
            <NutrientPill key={c} code={c} size="md" />
          ))}
        </div>
      )}
      <div className="absolute bottom-6 left-6 right-6 text-white">
        <p className="text-[10px] uppercase tracking-[0.2em] opacity-70">Nutrimate</p>
        <p className="text-lg font-semibold tracking-tight mt-0.5">{caption}</p>
      </div>
    </div>
  );
}
