"use client";

import { useRef } from "react";
import { motion, useScroll, useTransform, useReducedMotion } from "motion/react";
import { howItWorks } from "@/lib/copy";
import { Eyebrow } from "../primitives/Eyebrow";
import { RevealOnView } from "../motion/RevealOnView";

export function HowItWorks() {
  const reduce = useReducedMotion();
  const ref = useRef<HTMLDivElement>(null);
  const { scrollYProgress } = useScroll({ target: ref, offset: ["start 0.8", "end 0.4"] });
  const lineX = useTransform(scrollYProgress, [0, 1], reduce ? ["100%", "100%"] : ["0%", "100%"]);

  return (
    <section className="py-28 md:py-36 bg-[var(--color-surface-muted)]">
      <div ref={ref} className="relative mx-auto max-w-7xl px-6">
        <RevealOnView>
          <div className="max-w-2xl mb-20">
            <Eyebrow>How it works</Eyebrow>
            <h2 className="display-sans text-[clamp(36px,5vw,64px)] mt-5 leading-[1.0]">
              Three steps, then it disappears.
            </h2>
            <p className="mt-6 text-lg text-[var(--color-text-muted)] leading-relaxed">
              The best tracker is the one you forget you&apos;re using. Nutrimate is designed to fade into your routine within a week.
            </p>
          </div>
        </RevealOnView>

        {/* Connecting line that draws across as user scrolls */}
        <div className="relative">
          <div className="absolute top-12 left-6 right-6 hidden md:block">
            <div className="h-px bg-[var(--color-border)] relative overflow-hidden">
              <motion.div
                className="absolute inset-y-0 left-0 bg-[var(--color-accent)]"
                style={{ width: lineX }}
              />
            </div>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
            {howItWorks.map((s, i) => (
              <RevealOnView key={s.step} delay={i * 0.12}>
                <div className="relative pt-3">
                  <div className="flex items-center gap-3 mb-8">
                    <span className="grid place-items-center w-9 h-9 rounded-full bg-[var(--color-accent)] text-white text-[12px] font-bold tabular border-4 border-[var(--color-surface-muted)]">
                      {s.step}
                    </span>
                  </div>
                  <h3 className="text-2xl font-semibold tracking-tight mb-3">{s.title}</h3>
                  <p className="text-[15px] text-[var(--color-text-muted)] leading-relaxed">
                    {s.body}
                  </p>
                </div>
              </RevealOnView>
            ))}
          </div>
        </div>
      </div>
    </section>
  );
}
