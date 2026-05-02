"use client";

import { useEffect, useRef, useState } from "react";
import Image from "next/image";
import { AnimatePresence, motion, useScroll, useTransform, useReducedMotion } from "motion/react";
import { SplitText } from "../motion/SplitText";
import { MagneticButton } from "../motion/MagneticButton";
import { Eyebrow } from "../primitives/Eyebrow";
import { NutrientPill } from "../primitives/NutrientPill";
import { hero } from "@/lib/copy";
import { phoneMealPool, type PhoneMeal } from "@/lib/images";

export function Hero() {
  const reduce = useReducedMotion();
  const ref = useRef<HTMLDivElement>(null);
  const { scrollYProgress } = useScroll({ target: ref, offset: ["start start", "end start"] });

  // Background capsule cluster parallax
  const bgY = useTransform(scrollYProgress, [0, 1], reduce ? [0, 0] : [0, 200]);
  const bgRotate = useTransform(scrollYProgress, [0, 1], reduce ? [0, 0] : [0, -8]);
  // Phone mockup parallax + ring fill
  const phoneY = useTransform(scrollYProgress, [0, 1], reduce ? [0, 0] : [0, -80]);
  const ringProgress = useTransform(scrollYProgress, [0, 0.6], [0.18, 0.72]);

  return (
    <section
      ref={ref}
      className="relative pt-20 md:pt-24 pb-12 md:pb-16 overflow-hidden"
    >
      {/* Layered SVG capsule cluster (background, behind text) */}
      <motion.div
        aria-hidden
        style={{ y: bgY, rotate: bgRotate }}
        className="absolute inset-0 -z-10 pointer-events-none"
      >
        <CapsuleCluster />
      </motion.div>

      <div className="mx-auto max-w-7xl px-6 grid grid-cols-1 lg:grid-cols-[1.15fr_0.85fr] gap-16 items-center">
        {/* Left: copy */}
        <div>
          <Eyebrow>{hero.eyebrow}</Eyebrow>
          <div className="mt-6 mb-8">
            <SplitText
              as="h1"
              className="display-sans text-[clamp(36px,7vw,96px)] leading-[0.9] text-[var(--color-text)] text-balance"
            >
              {hero.headline}
            </SplitText>
          </div>

          <motion.p
            initial={{ opacity: 0, y: 12 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.6, duration: 0.7 }}
            className="text-lg leading-relaxed text-[var(--color-text-muted)] max-w-xl"
          >
            {hero.sub}
          </motion.p>

          <motion.div
            initial={{ opacity: 0, y: 12 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.8, duration: 0.7 }}
            className="mt-10 flex flex-wrap gap-3"
          >
            <MagneticButton
              href="/download"
              className="inline-flex items-center gap-3 h-14 px-6 rounded-2xl bg-[var(--color-text)] text-white hover:bg-black transition-colors"
            >
              <AppleIcon />
              <span className="text-left leading-tight">
                <small className="block text-[10px] text-[#9AA89F]">Download on the</small>
                <strong className="block text-[15px] font-semibold">App Store</strong>
              </span>
            </MagneticButton>
            <MagneticButton
              href="/download"
              className="inline-flex items-center gap-3 h-14 px-6 rounded-2xl bg-[var(--color-text)] text-white hover:bg-black transition-colors"
            >
              <PlayIcon />
              <span className="text-left leading-tight">
                <small className="block text-[10px] text-[#9AA89F]">Get it on</small>
                <strong className="block text-[15px] font-semibold">Google Play</strong>
              </span>
            </MagneticButton>
          </motion.div>
        </div>

        {/* Right: phone mockup */}
        <motion.div style={{ y: phoneY }} className="relative mx-auto">
          <PhoneMockup ringProgress={ringProgress} reduce={reduce ?? false} />
        </motion.div>
      </div>
    </section>
  );
}

/* ---------- Background SVG capsule cluster ---------- */
function CapsuleCluster() {
  return (
    <svg
      viewBox="0 0 1440 900"
      className="absolute -top-20 left-1/2 -translate-x-1/2 w-[140%] h-auto"
      preserveAspectRatio="xMidYMid slice"
    >
      <defs>
        <linearGradient id="cap-a" x1="0" y1="0" x2="1" y2="1">
          <stop offset="0%" stopColor="#FBEADB" stopOpacity="0.7" />
          <stop offset="100%" stopColor="#E88A3D" stopOpacity="0.18" />
        </linearGradient>
        <linearGradient id="cap-c" x1="0" y1="0" x2="1" y2="1">
          <stop offset="0%" stopColor="#E6F1E9" stopOpacity="0.8" />
          <stop offset="100%" stopColor="#2F7D4A" stopOpacity="0.16" />
        </linearGradient>
        <linearGradient id="cap-d" x1="0" y1="0" x2="1" y2="1">
          <stop offset="0%" stopColor="#F7EFD3" stopOpacity="0.8" />
          <stop offset="100%" stopColor="#C79B1A" stopOpacity="0.18" />
        </linearGradient>
      </defs>
      <g style={{ filter: "blur(0.5px)" }}>
        <Capsule cx={150} cy={120} w={340} h={120} angle={-22} fill="url(#cap-c)" />
        <Capsule cx={1200} cy={180} w={300} h={110} angle={18} fill="url(#cap-a)" />
        <Capsule cx={300} cy={680} w={420} h={140} angle={28} fill="url(#cap-d)" />
        <Capsule cx={1100} cy={620} w={360} h={120} angle={-14} fill="url(#cap-c)" />
      </g>
      <g style={{ filter: "blur(2px)", opacity: 0.7 }}>
        <Capsule cx={500} cy={300} w={200} h={70} angle={45} fill="url(#cap-a)" />
        <Capsule cx={950} cy={400} w={240} h={80} angle={-30} fill="url(#cap-d)" />
      </g>
    </svg>
  );
}

function Capsule({
  cx, cy, w, h, angle, fill,
}: { cx: number; cy: number; w: number; h: number; angle: number; fill: string }) {
  return (
    <rect
      x={cx - w / 2}
      y={cy - h / 2}
      width={w}
      height={h}
      rx={h / 2}
      fill={fill}
      transform={`rotate(${angle} ${cx} ${cy})`}
    />
  );
}

/* ---------- Phone mockup with animated ring ---------- */
function PhoneMockup({
  ringProgress,
  reduce,
}: {
  ringProgress: import("motion/react").MotionValue<number>;
  reduce: boolean;
}) {
  return (
    <div className="relative w-[320px] h-[640px] rounded-[44px] bg-[var(--color-surface)] border border-[var(--color-border)] p-3 shadow-[0_40px_120px_-32px_rgba(19,26,22,0.30)]">
      <div className="absolute top-3.5 left-1/2 -translate-x-1/2 w-24 h-5 bg-[var(--color-text)] rounded-full opacity-90 z-10" />
      <div
        className="w-full h-full rounded-[34px] p-12 pt-14 flex flex-col gap-3.5 overflow-hidden"
        style={{ background: "linear-gradient(180deg,#F2F6EE 0%,#E6F1E9 100%)" }}
      >
        {/* Today card */}
        <div className="bg-white border border-[var(--color-border)] rounded-2xl p-4 mt-3">
          <p className="eyebrow text-center mb-2">Today</p>
          <Ring progress={ringProgress} />
          <div className="flex flex-wrap gap-1.5 justify-center mt-3">
            <NutrientPill code="C" size="sm" />
            <NutrientPill code="D" size="sm" />
            <NutrientPill code="Fe" size="sm" />
            <NutrientPill code="B12" size="sm" />
            <NutrientPill code="Mg" size="sm" />
          </div>
        </div>

        {/* Animated meal card — items cycle places, fresh ones rotate in */}
        <MealCarousel pool={phoneMealPool} reduce={reduce} />
      </div>
    </div>
  );
}

/* ---------- Animated rotating meal list ----------
   Every 2.5s the bottom item rises to the top while the others slide
   down (a real "push down + go up" reorder via Framer's `layout`).
   Every 4th tick a fresh food enters at the bottom from the pool, so
   the user sees variety as well as motion. */
function MealCarousel({ pool, reduce }: { pool: PhoneMeal[]; reduce: boolean }) {
  const [visible, setVisible] = useState<PhoneMeal[]>(() => pool.slice(0, 3));
  const tickRef = useRef(0);
  const nextIdxRef = useRef(3);

  useEffect(() => {
    if (reduce || pool.length < 4) return;
    const id = setInterval(() => {
      tickRef.current += 1;
      if (tickRef.current % 4 === 0) {
        const nextFood = pool[nextIdxRef.current % pool.length]!;
        nextIdxRef.current += 1;
        setVisible((v) => [v[0]!, v[1]!, nextFood]);
      } else {
        setVisible((v) => [v[2]!, v[0]!, v[1]!]);
      }
    }, 2500);
    return () => clearInterval(id);
  }, [pool, reduce]);

  return (
    <div className="bg-white border border-[var(--color-border)] rounded-2xl p-3 overflow-hidden">
      <AnimatePresence mode="popLayout" initial={false}>
        {visible.map((food) => (
          <motion.div
            key={food.id}
            layout
            initial={reduce ? { opacity: 0 } : { opacity: 0, y: -22, scale: 0.96 }}
            animate={{ opacity: 1, y: 0, scale: 1 }}
            exit={reduce ? { opacity: 0 } : { opacity: 0, y: 22, scale: 0.96 }}
            transition={{ duration: 0.55, ease: [0.16, 1, 0.3, 1] }}
            className="flex gap-2.5 items-center py-1.5"
          >
            <div className="relative w-10 h-10 rounded-xl overflow-hidden flex-shrink-0 bg-[var(--color-surface-muted)]">
              <Image
                src={food.photo}
                alt={food.alt}
                fill
                sizes="40px"
                className="object-cover"
              />
            </div>
            <div className="flex-1 min-w-0">
              <p className="text-[12px] font-semibold leading-tight truncate">{food.name}</p>
              <p className="text-[10px] text-[var(--color-text-muted)] leading-tight truncate">
                {food.amount}
              </p>
            </div>
          </motion.div>
        ))}
      </AnimatePresence>
    </div>
  );
}

function Ring({ progress }: { progress: import("motion/react").MotionValue<number> }) {
  const r = 38;
  const c = 2 * Math.PI * r;
  const dash = useTransform(progress, (p) => `${c * p} ${c}`);
  const pct = useTransform(progress, (p) => Math.round(p * 100));

  return (
    <div className="relative mx-auto w-[100px] h-[100px]">
      <svg viewBox="0 0 100 100" className="w-full h-full -rotate-90">
        <circle cx="50" cy="50" r={r} fill="none" stroke="var(--color-surface-muted)" strokeWidth="8" />
        <motion.circle
          cx="50"
          cy="50"
          r={r}
          fill="none"
          stroke="var(--color-accent)"
          strokeWidth="8"
          strokeLinecap="round"
          style={{ strokeDasharray: dash }}
        />
      </svg>
      <div className="absolute inset-0 flex flex-col items-center justify-center">
        <motion.span className="text-[22px] font-bold tracking-tighter tabular leading-none">
          {pct}
        </motion.span>
        <span className="eyebrow mt-0.5">covered</span>
      </div>
    </div>
  );
}

function AppleIcon() {
  return (
    <svg width="22" height="22" viewBox="0 0 24 24" fill="currentColor">
      <path d="M17.05 20.28c-.98.95-2.05.8-3.08.35-1.09-.46-2.09-.48-3.24 0-1.44.62-2.2.44-3.06-.35C2.79 15.25 3.51 7.59 9.05 7.31c1.35.07 2.29.74 3.08.8 1.18-.24 2.31-.93 3.57-.84 1.51.12 2.65.72 3.4 1.8-3.12 1.87-2.38 5.98.48 7.13-.57 1.5-1.31 2.99-2.54 4.09zM12.03 7.25c-.15-2.23 1.66-4.07 3.74-4.25.29 2.58-2.34 4.5-3.74 4.25z" />
    </svg>
  );
}

function PlayIcon() {
  return (
    <svg width="20" height="22" viewBox="0 0 24 24" fill="currentColor">
      <path d="M3 2.5v19l8-9.5-8-9.5zm9.5 11l9 5.5-9.5-5L3 21.5l9.5-8zm0-3L3 2.5l9 5.5 9.5-5-9 8z" />
    </svg>
  );
}
