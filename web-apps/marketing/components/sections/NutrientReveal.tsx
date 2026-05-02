"use client";

import { useEffect, useRef, useState } from "react";
import {
  motion, useScroll, useTransform, useReducedMotion,
  AnimatePresence, type MotionValue,
} from "motion/react";
import { nutrients } from "@/lib/nutrients";
import { nutrientHues } from "@/lib/tokens";
import { Eyebrow } from "../primitives/Eyebrow";

// Tight scroll runway: each nutrient gets just enough scroll for the
// stage swap to feel deliberate, without a long blank stretch in between.
const TRACK_VH_PER_NUTRIENT = 30;

const pct = (value: number) => `${Number(value.toFixed(4))}%`;

export function NutrientReveal() {
  const reduce = useReducedMotion();
  const containerRef = useRef<HTMLDivElement>(null);
  const { scrollYProgress } = useScroll({
    target: containerRef,
    offset: ["start start", "end end"],
  });

  // Discrete index derived from scroll progress
  const [activeIdx, setActiveIdx] = useState(0);
  useEffect(() => {
    return scrollYProgress.on("change", (v) => {
      const i = Math.min(nutrients.length - 1, Math.max(0, Math.floor(v * nutrients.length)));
      setActiveIdx(i);
    });
  }, [scrollYProgress]);

  // Bar progress
  const barWidth = useTransform(scrollYProgress, [0, 1], ["0%", "100%"]);

  const active = nutrients[activeIdx];
  const hue = nutrientHues[active.code];

  return (
    <section
      ref={containerRef}
      className="relative"
      style={{ height: `${nutrients.length * TRACK_VH_PER_NUTRIENT}vh` }}
    >
      <div className="sticky top-0 h-screen flex items-center overflow-hidden">
        {/* Background tint that morphs to active nutrient hue */}
        <motion.div
          aria-hidden
          className="absolute inset-0 -z-10"
          animate={{
            background: `radial-gradient(ellipse 90% 80% at 65% 50%, ${hue.bg}cc 0%, var(--color-bg) 60%)`,
          }}
          transition={{ duration: 0.9, ease: [0.2, 0.65, 0.3, 0.9] }}
        />

        <div className="mx-auto max-w-7xl px-6 w-full grid grid-cols-1 lg:grid-cols-[0.85fr_1fr] gap-12 lg:gap-20 items-center">
          {/* ───────── LEFT: number, name, body, stats, progress ───────── */}
          <div className="relative z-10">
            <Eyebrow>What we track</Eyebrow>

            {/* Big tabular index — counts through 01..12 */}
            <div className="flex items-baseline gap-3 mt-6 mb-1 leading-none">
              <div className="relative h-[clamp(96px,15vw,168px)] w-[clamp(120px,18vw,220px)] overflow-hidden">
                <AnimatePresence mode="popLayout">
                  <motion.span
                    key={active.code}
                    initial={{ y: "100%", opacity: 0 }}
                    animate={{ y: "0%", opacity: 1 }}
                    exit={{ y: "-100%", opacity: 0 }}
                    transition={{ duration: 0.55, ease: [0.2, 0.65, 0.3, 0.9] }}
                    className="absolute inset-0 display-sans tabular leading-[0.85] font-bold"
                    style={{
                      color: hue.fill,
                      fontSize: "clamp(96px, 15vw, 168px)",
                      letterSpacing: "-0.06em",
                    }}
                  >
                    {String(activeIdx + 1).padStart(2, "0")}
                  </motion.span>
                </AnimatePresence>
              </div>
              <span className="display-sans tabular text-[var(--color-text-muted)] opacity-30 font-bold"
                    style={{ fontSize: "clamp(28px, 3.5vw, 44px)", letterSpacing: "-0.04em" }}>
                / {nutrients.length}
              </span>
            </div>

            {/* Name + body — cross-fades on change */}
            <AnimatePresence mode="wait">
              <motion.div
                key={active.code}
                initial={{ opacity: 0, y: 16 }}
                animate={{ opacity: 1, y: 0 }}
                exit={{ opacity: 0, y: -10 }}
                transition={{ duration: 0.4, ease: [0.2, 0.65, 0.3, 0.9] }}
              >
                <h2
                  className="display-sans leading-[0.95] mt-4"
                  style={{ fontSize: "clamp(40px, 5.2vw, 68px)", letterSpacing: "-0.03em" }}
                >
                  {active.name}
                </h2>

                <p className="mt-6 text-xl text-[var(--color-text)] max-w-md leading-snug">
                  {active.oneLiner}
                </p>

                <div className="mt-10 flex flex-wrap items-end gap-x-10 gap-y-4">
                  <Stat label="Unit" value={active.unit} />
                  <Stat label="Group" value={active.group} capitalize />
                </div>
              </motion.div>
            </AnimatePresence>

            {/* Linear scroll progress */}
            <div className="mt-12 max-w-md">
              <div className="h-px bg-[var(--color-border)] relative overflow-hidden rounded-full">
                <motion.div
                  className="absolute inset-y-0 left-0 rounded-full"
                  style={{ width: barWidth, background: hue.fill }}
                />
              </div>
              <p className="eyebrow mt-3 text-[10px]">Keep scrolling</p>
            </div>
          </div>

          {/* ───────── RIGHT: theatrical stage with orbital companions ───────── */}
          <Stage activeIdx={activeIdx} reduce={reduce ?? false} progress={scrollYProgress} />
        </div>
      </div>
    </section>
  );
}

/* ---------- Stat ---------- */

function Stat({ label, value, capitalize }: { label: string; value: string; capitalize?: boolean }) {
  return (
    <div>
      <span className="eyebrow block">{label}</span>
      <span className={`text-2xl font-semibold tabular mt-1 block ${capitalize ? "capitalize" : ""}`}>
        {value}
      </span>
    </div>
  );
}

/* ---------- Stage with big pill + orbiting companions + breathing aura ---------- */

function Stage({
  activeIdx, reduce, progress,
}: {
  activeIdx: number;
  reduce: boolean;
  progress: MotionValue<number>;
}) {
  const active = nutrients[activeIdx];
  const hue = nutrientHues[active.code];

  // Slow rotation of the entire orbit (always-on micro-motion)
  const orbitRotate = useTransform(progress, [0, 1], reduce ? [0, 0] : [0, 360]);

  // Mobile sizing — orbital pills and animate values are pixel based, so we
  // need state to swap them per breakpoint (CSS clamp can't drive Framer
  // animate numbers without losing interpolation).
  const [isMobile, setIsMobile] = useState(false);
  useEffect(() => {
    const check = () => setIsMobile(window.innerWidth < 640);
    check();
    window.addEventListener("resize", check);
    return () => window.removeEventListener("resize", check);
  }, []);
  const orbitSize = isMobile ? 42 : 56;
  const orbitFont = isMobile ? 11 : 13;

  return (
    <div className="relative aspect-square w-full max-w-[640px] mx-auto">
      {/* Decorative concentric orbit lines */}
      <svg viewBox="0 0 100 100" className="absolute inset-0 w-full h-full" aria-hidden>
        <circle cx="50" cy="50" r="42" fill="none" stroke="var(--color-border)" strokeWidth="0.15" strokeDasharray="0.6 1.2" />
        <circle cx="50" cy="50" r="32" fill="none" stroke="var(--color-border)" strokeWidth="0.15" strokeDasharray="0.4 1.6" />
        <circle cx="50" cy="50" r="22" fill="none" stroke="var(--color-border)" strokeWidth="0.15" strokeDasharray="0.3 2.0" />
      </svg>

      {/* Breathing aura behind the stage */}
      {!reduce && (
        <motion.div
          aria-hidden
          className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 rounded-full"
          style={{
            width: "70%",
            height: "70%",
            background: `radial-gradient(circle, ${hue.fill}33 0%, transparent 60%)`,
          }}
          animate={{ scale: [1, 1.12, 1], opacity: [0.55, 0.85, 0.55] }}
          transition={{ duration: 5, repeat: Infinity, ease: "easeInOut" }}
        />
      )}

      {/* Orbital small pills — rotate slowly on scroll */}
      <motion.div
        className="absolute inset-0"
        style={{ rotate: orbitRotate }}
      >
        {nutrients.map((n, i) => {
          const total = nutrients.length;
          const angle = (i / total) * Math.PI * 2 - Math.PI / 2; // start at 12 o'clock
          const r = 42;
          const x = 50 + r * Math.cos(angle);
          const y = 50 + r * Math.sin(angle);
          const isActive = i === activeIdx;
          const nh = nutrientHues[n.code];

          return (
            <motion.div
              key={n.code}
              suppressHydrationWarning
              className="absolute -translate-x-1/2 -translate-y-1/2 grid place-items-center rounded-full font-bold tracking-tighter shadow-[0_8px_24px_-12px_rgba(19,26,22,0.18)]"
              style={{
                left: pct(x),
                top: pct(y),
                backgroundColor: nh.bg,
                color: nh.fill,
              }}
              initial={false}
              animate={{
                width: isActive ? 0 : orbitSize,
                height: isActive ? 0 : orbitSize,
                fontSize: isActive ? 0 : orbitFont,
                opacity: isActive ? 0 : 1,
                scale: isActive ? 0 : 1,
              }}
              transition={{ duration: 0.45, ease: [0.2, 0.65, 0.3, 0.9] }}
            >
              {n.code}
            </motion.div>
          );
        })}
      </motion.div>

      {/* Big stage pill — cross-blurs on change */}
      <div className="absolute inset-0 grid place-items-center pointer-events-none">
        <AnimatePresence mode="wait">
          <motion.div
            key={active.code}
            initial={{ scale: 0.55, opacity: 0, filter: "blur(28px)" }}
            animate={{ scale: 1, opacity: 1, filter: "blur(0px)" }}
            exit={{ scale: 1.35, opacity: 0, filter: "blur(28px)" }}
            transition={{ duration: 0.55, ease: [0.2, 0.65, 0.3, 0.9] }}
            className="relative z-10"
          >
            <motion.div
              animate={reduce ? {} : { y: [-6, 6, -6] }}
              transition={{ duration: 6, repeat: Infinity, ease: "easeInOut" }}
              className="grid place-items-center rounded-full font-bold tracking-tighter"
              style={{
                width: "min(58vw, 40vh, 320px)",
                height: "min(58vw, 40vh, 320px)",
                fontSize: "min(24vw, 15vh, 124px)",
                background: hue.bg,
                color: hue.fill,
                boxShadow: `0 50px 120px -28px ${hue.fill}55, inset 0 0 0 1px ${hue.fill}10`,
              }}
            >
              {active.code}
            </motion.div>
          </motion.div>
        </AnimatePresence>
      </div>

      {/* Tiny floating dots — adds life when settled */}
      {!reduce && (
        <>
          <FloatingDot top="12%" left="22%" delay={0}   color={hue.fill} />
          <FloatingDot top="80%" left="74%" delay={1.2} color={hue.fill} />
          <FloatingDot top="68%" left="14%" delay={2.4} color={hue.fill} />
        </>
      )}
    </div>
  );
}

function FloatingDot({ top, left, delay, color }: { top: string; left: string; delay: number; color: string }) {
  return (
    <motion.span
      aria-hidden
      className="absolute w-1.5 h-1.5 rounded-full"
      style={{ top, left, background: color }}
      animate={{ y: [-8, 8, -8], opacity: [0.2, 0.7, 0.2] }}
      transition={{ duration: 5, repeat: Infinity, delay, ease: "easeInOut" }}
    />
  );
}
