"use client";

import { useEffect, useRef, useState } from "react";
import Image from "next/image";
import {
  AnimatePresence,
  motion,
  useMotionValue,
  useReducedMotion,
  useScroll,
  useSpring,
  useTransform,
} from "motion/react";
import { proteinNatureGallery } from "@/lib/images";
import { Eyebrow } from "../primitives/Eyebrow";

type Caption = {
  kicker: string;
  line: string;
  tag: string;
  serving: string;
  nutrients: { label: string; value: string; pct: number }[];
  hue: string;
  bgHue: string;
};

const captions: Caption[] = [
  {
    kicker: "Salmon",
    line: "Wild-caught richness — vitamin D where most diets fall short, omega-3s for the brain, and clean complete protein on one plate.",
    tag: "Protein · Vitamin D",
    serving: "100 g cooked fillet",
    nutrients: [
      { label: "Vitamin D", value: "13.1 µg", pct: 87 },
      { label: "Omega-3",   value: "2.6 g",   pct: 70 },
      { label: "Protein",   value: "25 g",    pct: 50 },
      { label: "B12",       value: "3.2 µg",  pct: 95 },
    ],
    hue: "var(--color-nut-d)",
    bgHue: "var(--color-nut-d-bg)",
  },
  {
    kicker: "Greens",
    line: "A bowl that quietly carries folate, magnesium, and vitamin C — without any of the smoothie-bar performance.",
    tag: "Plants · Minerals",
    serving: "1 mixed bowl",
    nutrients: [
      { label: "Folate",    value: "194 µg",  pct: 49 },
      { label: "Magnesium", value: "157 mg",  pct: 45 },
      { label: "Vitamin C", value: "30 mg",   pct: 33 },
      { label: "Fiber",     value: "8 g",     pct: 32 },
    ],
    hue: "var(--color-nut-c)",
    bgHue: "var(--color-nut-c-bg)",
  },
  {
    kicker: "Almonds",
    line: "Small foods still matter — vitamin E for skin and circulation, magnesium for sleep, fats that don't spike.",
    tag: "Vitamin E · Magnesium",
    serving: "30 g handful",
    nutrients: [
      { label: "Vitamin E", value: "7.7 mg",  pct: 52 },
      { label: "Magnesium", value: "80 mg",   pct: 23 },
      { label: "Healthy fats", value: "14 g", pct: 22 },
      { label: "Fiber",     value: "3.5 g",   pct: 14 },
    ],
    hue: "var(--color-nut-e)",
    bgHue: "var(--color-nut-e-bg)",
  },
  {
    kicker: "Avocado",
    line: "Fiber, potassium, and soft monounsaturated fats — reads better as food than as a pill, and your gut agrees.",
    tag: "Whole-food energy",
    serving: "1 medium fruit",
    nutrients: [
      { label: "Potassium", value: "975 mg",  pct: 28 },
      { label: "Fiber",     value: "13.5 g",  pct: 54 },
      { label: "Vitamin K", value: "42 µg",   pct: 35 },
      { label: "Folate",    value: "163 µg",  pct: 41 },
    ],
    hue: "var(--color-nut-mg)",
    bgHue: "var(--color-nut-mg-bg)",
  },
  {
    kicker: "Chickpeas",
    line: "Plant protein, iron, and folate — without the page turning clinical. They show up in bowls where they need to be.",
    tag: "Plant protein · Iron",
    serving: "1 cup cooked",
    nutrients: [
      { label: "Iron",    value: "4.7 mg",  pct: 32 },
      { label: "Protein", value: "15 g",    pct: 30 },
      { label: "Folate",  value: "282 µg",  pct: 71 },
      { label: "Fiber",   value: "12.5 g",  pct: 50 },
    ],
    hue: "var(--color-nut-fe)",
    bgHue: "var(--color-nut-fe-bg)",
  },
  {
    kicker: "Spinach",
    line: "Quiet green volume — vitamin K and minerals doing the work. Cooked or raw, it earns its place.",
    tag: "Vitamin K · Daily greens",
    serving: "100 g raw",
    nutrients: [
      { label: "Vitamin K", value: "483 µg",  pct: 100 },
      { label: "Iron",      value: "2.7 mg",  pct: 18 },
      { label: "Folate",    value: "194 µg",  pct: 49 },
      { label: "Magnesium", value: "79 mg",   pct: 23 },
    ],
    hue: "var(--color-nut-k)",
    bgHue: "var(--color-nut-k-bg)",
  },
];

// 6 * 50 = 300vh total; the sticky child is 100vh, so the pin holds for 200vh
// — ~33vh per food. Tight enough that the deck flip lands on each step.
const TRACK_VH_PER_ITEM = 50;

export function VitaminGallery() {
  const reduce = useReducedMotion();
  const sectionRef = useRef<HTMLElement>(null);

  const { scrollYProgress } = useScroll({
    target: sectionRef,
    offset: ["start start", "end end"],
  });

  const [active, setActive] = useState(0);
  useEffect(() => {
    return scrollYProgress.on("change", (v) => {
      const i = Math.min(
        captions.length - 1,
        Math.max(0, Math.floor(v * captions.length)),
      );
      setActive(i);
    });
  }, [scrollYProgress]);

  const progressWidth = useTransform(scrollYProgress, [0, 1], ["0%", "100%"]);

  const activeCaption = captions[active] ?? captions[0];
  const activePhoto = proteinNatureGallery[active] ?? proteinNatureGallery[0];

  const scrollToIndex = (i: number) => {
    const el = sectionRef.current;
    if (!el) return;
    const rect = el.getBoundingClientRect();
    const sectionTop = window.scrollY + rect.top;
    const scrollableDistance = el.offsetHeight - window.innerHeight;
    const target =
      sectionTop + ((i + 0.5) / captions.length) * scrollableDistance;
    window.scrollTo({
      top: target,
      behavior: reduce ? "auto" : "smooth",
    });
  };

  return (
    <section
      ref={sectionRef}
      className="relative bg-[var(--color-bg)] [overflow:clip]"
      style={{ height: `${captions.length * TRACK_VH_PER_ITEM}vh` }}
    >
      <div className="sticky top-0 h-screen flex flex-col">
        {/* Soft hue-morphing wash behind everything */}
        <motion.div
          aria-hidden
          className="absolute inset-0 -z-10 pointer-events-none"
          animate={{
            background: `radial-gradient(ellipse 60% 50% at 30% 40%, ${activeCaption.bgHue}b3 0%, var(--color-bg) 65%)`,
          }}
          transition={{ duration: 1.0, ease: [0.2, 0.65, 0.3, 0.9] }}
        />

        {/* ================= TOP STRIP — eyebrow / heading / progress ================= */}
        <header className="relative z-10 mx-auto w-full max-w-7xl px-5 sm:px-8 pt-6 md:pt-8 pb-4 md:pb-6">
          <div className="flex items-end justify-between gap-6 flex-wrap">
            <div>
              <Eyebrow className="text-[var(--color-warn)]">Food first</Eyebrow>
              <h2
                className="display mt-3 text-[30px] sm:text-[44px] lg:text-[56px] leading-[0.95] text-[var(--color-text)]"
                style={{ letterSpacing: "-0.02em" }}
              >
                A tree of{" "}
                <span
                  className="italic"
                  style={{ color: "var(--color-accent-deep)" }}
                >
                  nutrients.
                </span>
              </h2>
            </div>
            <div className="flex items-end gap-5">
              <div className="hidden sm:block tabular eyebrow text-[var(--color-text-muted)]">
                <span className="text-[var(--color-text)] text-[18px] font-bold tracking-tight">
                  {String(active + 1).padStart(2, "0")}
                </span>
                <span className="opacity-50 text-[14px]"> / {String(captions.length).padStart(2, "0")}</span>
              </div>
              <div className="w-44 sm:w-56">
                <div className="relative h-px overflow-hidden rounded-full bg-[var(--color-border)]">
                  <motion.div
                    className="absolute inset-y-0 left-0 rounded-full"
                    style={{ width: progressWidth, background: activeCaption.hue }}
                  />
                </div>
                <p className="eyebrow mt-2 text-[10px] text-right text-[var(--color-text-muted)]">
                  Scroll · hover · click
                </p>
              </div>
            </div>
          </div>
        </header>

        {/* Hairline divider */}
        <div
          aria-hidden
          className="mx-auto w-full max-w-7xl px-5 sm:px-8"
        >
          <div className="h-px bg-[var(--color-border)] opacity-60" />
        </div>

        {/* ================= MAIN STAGE ================= */}
        <main className="relative z-10 flex-1 mx-auto w-full max-w-7xl px-5 sm:px-8 py-3 md:py-7 grid grid-cols-1 lg:grid-cols-12 gap-3 lg:gap-12 items-stretch">
          {/* LEFT — vertical thumbnail rail (lg) */}
          <aside className="hidden lg:flex lg:col-span-1 flex-col items-center justify-center gap-4">
            {captions.map((cap, i) => {
              const isActive = i === active;
              const photo = proteinNatureGallery[i] ?? proteinNatureGallery[0];
              return (
                <button
                  key={cap.kicker}
                  type="button"
                  onClick={() => scrollToIndex(i)}
                  onMouseEnter={() => setActive(i)}
                  onFocus={() => setActive(i)}
                  aria-label={`Jump to ${cap.kicker}`}
                  aria-pressed={isActive}
                  className="group relative flex items-center gap-3 focus:outline-none"
                >
                  {/* Active accent bar */}
                  <motion.span
                    aria-hidden
                    className="absolute -left-3 top-1/2 -translate-y-1/2 block w-px"
                    animate={{
                      height: isActive ? 28 : 0,
                      backgroundColor: cap.hue,
                    }}
                    transition={{ duration: 0.45, ease: [0.16, 1, 0.3, 1] }}
                  />
                  <motion.span
                    className="relative block rounded-full overflow-hidden bg-white"
                    animate={{ width: isActive ? 56 : 36, height: isActive ? 56 : 36 }}
                    transition={{ duration: 0.45, ease: [0.16, 1, 0.3, 1] }}
                    style={{
                      outline: isActive
                        ? `2px solid ${cap.hue}`
                        : "1px solid var(--color-border)",
                      outlineOffset: isActive ? 3 : 0,
                      boxShadow:
                        "0 12px 30px -18px rgba(19,26,22,0.4), 0 2px 6px -3px rgba(19,26,22,0.15)",
                    }}
                  >
                    <Image
                      src={photo.url}
                      alt={photo.alt}
                      fill
                      sizes="56px"
                      className="object-cover"
                    />
                  </motion.span>
                </button>
              );
            })}
          </aside>

          {/* CENTER — recipe-book card deck */}
          <div className="lg:col-span-6 relative">
            <PhotoStage
              activeCaption={activeCaption}
              activePhoto={activePhoto}
              reduce={reduce ?? false}
            />
          </div>

          {/* RIGHT — info panel */}
          <div className="lg:col-span-5 relative flex flex-col justify-center min-h-0">
            <AnimatePresence mode="wait">
              <motion.div
                key={activeCaption.kicker}
                initial={reduce ? { opacity: 1 } : { opacity: 0, x: 16 }}
                animate={{ opacity: 1, x: 0 }}
                exit={reduce ? { opacity: 0 } : { opacity: 0, x: -16 }}
                transition={{ duration: 0.55, ease: [0.16, 1, 0.3, 1] }}
              >
                {/* Big tabular index */}
                <div className="flex items-baseline gap-2 leading-none mb-2 sm:mb-3">
                  <span
                    className="display-sans tabular text-[44px] sm:text-[88px] lg:text-[112px] leading-[0.85] font-bold"
                    style={{ color: activeCaption.hue, letterSpacing: "-0.06em" }}
                  >
                    {String(active + 1).padStart(2, "0")}
                  </span>
                  <span
                    className="display-sans tabular text-[14px] sm:text-[22px] opacity-30 font-bold"
                    style={{ letterSpacing: "-0.04em" }}
                  >
                    / {String(captions.length).padStart(2, "0")}
                  </span>
                </div>

                {/* Name */}
                <h3
                  className="display text-[30px] sm:text-[56px] lg:text-[72px] leading-[0.95] text-[var(--color-text)] text-balance"
                  style={{ letterSpacing: "-0.02em" }}
                >
                  {activeCaption.kicker}
                  <span style={{ color: activeCaption.hue }}>.</span>
                </h3>

                {/* Caption */}
                <p className="mt-3 sm:mt-5 text-[13px] sm:text-base lg:text-[17px] leading-snug sm:leading-relaxed text-[var(--color-text-muted)] max-w-md">
                  {activeCaption.line}
                </p>

                {/* Hairline divider */}
                <div
                  aria-hidden
                  className="my-3 sm:my-6 h-px w-12 bg-[var(--color-border)]"
                  style={{ background: activeCaption.hue, opacity: 0.6 }}
                />

                {/* Nutrient grid */}
                <ul className="grid grid-cols-2 gap-x-5 gap-y-2.5 sm:gap-y-4 max-w-md">
                  {activeCaption.nutrients.map((n, i) => (
                    <motion.li
                      key={n.label}
                      initial={reduce ? { opacity: 1 } : { opacity: 0, y: 8 }}
                      animate={{ opacity: 1, y: 0 }}
                      transition={{
                        duration: 0.4,
                        delay: 0.15 + i * 0.07,
                        ease: [0.16, 1, 0.3, 1],
                      }}
                    >
                      <div className="flex items-baseline justify-between gap-2">
                        <span className="eyebrow text-[10px] text-[var(--color-text-muted)]">
                          {n.label}
                        </span>
                        <span
                          className="tabular text-[13px] font-bold"
                          style={{ color: activeCaption.hue }}
                        >
                          {n.value}
                        </span>
                      </div>
                      <div className="mt-1.5 h-1 rounded-full bg-[var(--color-border)] overflow-hidden">
                        <motion.div
                          initial={reduce ? { width: `${n.pct}%` } : { width: 0 }}
                          animate={{ width: `${n.pct}%` }}
                          transition={{
                            duration: 0.8,
                            delay: 0.25 + i * 0.07,
                            ease: [0.16, 1, 0.3, 1],
                          }}
                          className="h-full rounded-full"
                          style={{ background: activeCaption.hue }}
                        />
                      </div>
                    </motion.li>
                  ))}
                </ul>

                <p className="eyebrow mt-5 text-[10px] text-[var(--color-text-muted)]">
                  Bars are % of an adult daily reference (USDA / NIH)
                </p>
              </motion.div>
            </AnimatePresence>
          </div>
        </main>

        {/* ================= BOTTOM RAIL — horizontal thumbnails (mobile + tablet) ================= */}
        <footer className="relative z-10 mx-auto w-full max-w-7xl px-5 sm:px-8 pb-5 md:pb-7 lg:hidden">
          <div className="overflow-x-auto -mx-2 px-2 [scrollbar-width:none] [&::-webkit-scrollbar]:hidden">
            <div className="flex items-end justify-start sm:justify-center gap-3 min-w-max">
              {captions.map((cap, i) => {
                const isActive = i === active;
                const photo = proteinNatureGallery[i] ?? proteinNatureGallery[0];
                return (
                  <button
                    key={cap.kicker}
                    type="button"
                    onClick={() => scrollToIndex(i)}
                    onMouseEnter={() => setActive(i)}
                    onFocus={() => setActive(i)}
                    aria-pressed={isActive}
                    aria-label={`Jump to ${cap.kicker}`}
                    className="group flex flex-col items-center gap-1.5 flex-shrink-0 focus:outline-none"
                  >
                    <motion.span
                      className="block rounded-full overflow-hidden bg-white"
                      animate={{ width: isActive ? 56 : 40, height: isActive ? 56 : 40 }}
                      transition={{ duration: 0.45, ease: [0.16, 1, 0.3, 1] }}
                      style={{
                        outline: isActive
                          ? `2px solid ${cap.hue}`
                          : "1px solid var(--color-border)",
                        outlineOffset: isActive ? 3 : 0,
                        boxShadow:
                          "0 10px 22px -14px rgba(19,26,22,0.35), 0 2px 4px -2px rgba(19,26,22,0.12)",
                      }}
                    >
                      <Image
                        src={photo.url}
                        alt={photo.alt}
                        fill
                        sizes="56px"
                        className="object-cover"
                      />
                    </motion.span>
                    <motion.span
                      className="block eyebrow text-[9px] tracking-[0.14em] transition-colors"
                      animate={{
                        color: isActive
                          ? cap.hue
                          : "var(--color-text-muted)",
                      }}
                      transition={{ duration: 0.4 }}
                    >
                      {cap.kicker}
                    </motion.span>
                  </button>
                );
              })}
            </div>
          </div>
        </footer>
      </div>
    </section>
  );
}

/* ───────── Editorial gallery-print stage ─────────
   Single hero photo treated like a framed print: a coloured matte mounts
   behind it, the photo breathes (Ken Burns), and changes wipe in via a
   horizontal clip-path mask — no peek cards, no blur, no flip. */
function PhotoStage({
  activeCaption,
  activePhoto,
  reduce,
}: {
  activeCaption: Caption;
  activePhoto: (typeof proteinNatureGallery)[number];
  reduce: boolean;
}) {
  const wrapRef = useRef<HTMLDivElement>(null);

  const mx = useMotionValue(0);
  const my = useMotionValue(0);
  const tiltX = useSpring(useTransform(my, [-0.5, 0.5], [4, -4]), {
    stiffness: 140,
    damping: 18,
    mass: 0.4,
  });
  const tiltY = useSpring(useTransform(mx, [-0.5, 0.5], [-6, 6]), {
    stiffness: 140,
    damping: 18,
    mass: 0.4,
  });

  const onMove = (e: React.MouseEvent) => {
    if (reduce) return;
    const r = wrapRef.current?.getBoundingClientRect();
    if (!r) return;
    mx.set((e.clientX - r.left) / r.width - 0.5);
    my.set((e.clientY - r.top) / r.height - 0.5);
  };
  const onLeave = () => {
    mx.set(0);
    my.set(0);
  };

  return (
    <div
      ref={wrapRef}
      onMouseMove={onMove}
      onMouseLeave={onLeave}
      className="relative h-full w-full lg:min-h-0 aspect-[5/3] sm:aspect-[5/4] lg:aspect-auto"
      style={{ perspective: 1800 }}
    >
      <motion.div
        className="absolute inset-0"
        style={{
          rotateX: reduce ? 0 : tiltX,
          rotateY: reduce ? 0 : tiltY,
          transformStyle: "preserve-3d",
        }}
      >
        {/* Coloured matte mounted behind the print, offset like a gallery frame */}
        <motion.div
          aria-hidden
          className="absolute inset-0 rounded-[24px]"
          animate={{ backgroundColor: activeCaption.bgHue }}
          transition={{ duration: 0.7, ease: [0.16, 1, 0.3, 1] }}
          style={{
            transform: "translate(20px, 20px) rotate(1.4deg)",
            opacity: 0.75,
            boxShadow: "0 24px 48px -28px rgba(19,26,22,0.35)",
          }}
        />

        {/* Photo card */}
        <div
          className="absolute inset-0 overflow-hidden rounded-2xl bg-[var(--color-surface)]"
          style={{
            boxShadow:
              "0 50px 100px -50px rgba(19,26,22,0.45), 0 8px 24px -12px rgba(19,26,22,0.18), inset 0 0 0 1px rgba(255,255,255,0.4)",
          }}
        >
          <AnimatePresence mode="popLayout">
            <motion.div
              key={activeCaption.kicker}
              className="absolute inset-0"
              initial={
                reduce
                  ? { clipPath: "inset(0% 0% 0% 0%)" }
                  : { clipPath: "inset(0% 100% 0% 0%)" }
              }
              animate={{ clipPath: "inset(0% 0% 0% 0%)" }}
              exit={
                reduce
                  ? { opacity: 0 }
                  : { clipPath: "inset(0% 0% 0% 100%)" }
              }
              transition={{ duration: 0.85, ease: [0.65, 0, 0.35, 1] }}
            >
              {/* Ken Burns: slow drift + zoom while idle */}
              <motion.div
                className="absolute inset-0"
                animate={
                  reduce
                    ? {}
                    : {
                        scale: [1.04, 1.1, 1.04],
                        x: [0, -10, 0],
                        y: [0, 6, 0],
                      }
                }
                transition={{ duration: 14, repeat: Infinity, ease: "easeInOut" }}
              >
                <Image
                  src={activePhoto.url}
                  alt={activePhoto.alt}
                  fill
                  sizes="(max-width: 640px) 100vw, (max-width: 1024px) 90vw, 600px"
                  className="object-cover"
                  priority
                />
              </motion.div>

              <div
                aria-hidden
                className="absolute inset-x-0 bottom-0 h-1/3"
                style={{
                  background:
                    "linear-gradient(to top, rgba(19,26,22,0.55) 0%, rgba(19,26,22,0.0) 100%)",
                }}
              />
              <div className="absolute left-4 bottom-4 right-4 flex items-end justify-between gap-3 text-white">
                <span className="eyebrow text-[10px] tracking-[0.18em] text-white/85">
                  Food · {activeCaption.kicker}
                </span>
                <span
                  className="rounded-full px-2.5 py-1 text-[10px] font-semibold uppercase tracking-[0.12em] backdrop-blur"
                  style={{
                    background: "rgba(255,255,255,0.18)",
                    color: "white",
                    boxShadow: "inset 0 0 0 1px rgba(255,255,255,0.25)",
                  }}
                >
                  {activeCaption.serving}
                </span>
              </div>
            </motion.div>
          </AnimatePresence>
        </div>
      </motion.div>

      {/* Floating hue chip — outside the tilt so it stays steady */}
      <motion.div
        className="absolute -top-3 -left-3 z-20 hidden sm:flex items-center gap-2 rounded-full bg-white px-3 py-1.5 text-[11px] font-semibold uppercase tracking-[0.1em]"
        animate={{ color: activeCaption.hue }}
        transition={{ duration: 0.5 }}
        style={{
          boxShadow:
            "0 12px 28px -16px rgba(19,26,22,0.35), inset 0 0 0 1px var(--color-border)",
        }}
      >
        <motion.span
          className="block w-2 h-2 rounded-full"
          animate={{ background: activeCaption.hue }}
          transition={{ duration: 0.5 }}
        />
        {activeCaption.tag}
      </motion.div>
    </div>
  );
}
