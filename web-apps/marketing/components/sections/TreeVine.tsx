"use client";

import { motion, useTransform, type MotionValue } from "motion/react";

/**
 * Shared vine pieces used by both VitaminGallery and FeaturesGrid:
 * - <Trunk>      a vertical center line that draws as you scroll, using
 *                clip-path on a static gradient (no SVG pathLength bugs).
 * - <BranchSvg>  a small per-row curve from the trunk to the image edge.
 * - <StopBadge>  the numbered circle that sits on the trunk at every row.
 */

export function Trunk({ progress }: { progress: MotionValue<number> }) {
  // Clip the bottom of the gradient based on scroll progress: 100% clipped at
  // start (invisible), 0% clipped at end (fully visible).
  const clipPath = useTransform(progress, (v) => `inset(0 0 ${(1 - v) * 100}% 0)`);

  return (
    <div
      aria-hidden
      className="hidden lg:block absolute left-1/2 top-0 bottom-0 -translate-x-1/2 w-[2px] z-0 pointer-events-none"
    >
      {/* Faint solid backdrop trunk */}
      <div
        className="absolute inset-0 rounded-full"
        style={{ background: "var(--color-border)", opacity: 0.55 }}
      />
      {/* Drawn portion — clipped from below as scroll progresses */}
      <motion.div
        className="absolute inset-0 rounded-full"
        style={{
          background: "linear-gradient(to bottom, #3B9159 0%, #2F7D4A 55%, #1E5A34 100%)",
          clipPath,
        }}
      />
    </div>
  );
}

export function BranchSvg({
  side, inView, delay = 0.7,
}: {
  side: "left" | "right";
  inView: boolean;
  delay?: number;
}) {
  // Branch occupies the gap between the trunk (50%) and the image inner
  // edge (~33% on its side). Vertically centered in the row.
  const positionStyle =
    side === "left"
      ? { left: "33.333%", right: "50%" }
      : { right: "33.333%", left: "50%" };

  // Path data — a graceful drooping cubic from trunk to image edge.
  const dLeft  = "M 100 30 C 80 35, 30 65, 0 70";
  const dRight = "M 0 30 C 20 35, 70 65, 100 70";

  return (
    <div
      aria-hidden
      className="hidden lg:block absolute top-1/2 -translate-y-1/2 z-10 pointer-events-none"
      style={{ height: 80, ...positionStyle }}
    >
      <svg
        width="100%"
        height="100%"
        viewBox="0 0 100 80"
        preserveAspectRatio="none"
      >
        <motion.path
          d={side === "left" ? dLeft : dRight}
          fill="none"
          stroke="#2F7D4A"
          strokeWidth="2"
          strokeLinecap="round"
          vectorEffect="non-scaling-stroke"
          initial={{ pathLength: 0 }}
          animate={inView ? { pathLength: 1 } : { pathLength: 0 }}
          transition={{ duration: 0.85, delay, ease: [0.2, 0.65, 0.3, 0.9] }}
        />
        {/* Leaf-tip dot at the branch end */}
        <motion.circle
          cx={side === "left" ? 0 : 100}
          cy={70}
          r="4"
          fill="#1E5A34"
          vectorEffect="non-scaling-stroke"
          initial={{ scale: 0, opacity: 0 }}
          animate={inView ? { scale: 1, opacity: 1 } : {}}
          transition={{ duration: 0.4, delay: delay + 0.7 }}
          style={{ transformOrigin: side === "left" ? "0 70px" : "100px 70px" }}
        />
      </svg>
    </div>
  );
}

export function StopBadge({
  index, inView, delay = 0.4,
}: {
  index: number;
  inView: boolean;
  delay?: number;
}) {
  return (
    <motion.div
      aria-hidden
      initial={{ opacity: 0, scale: 0 }}
      animate={inView ? { opacity: 1, scale: 1 } : {}}
      transition={{ duration: 0.55, ease: [0.2, 0.85, 0.3, 1.05], delay }}
      className="hidden lg:grid place-items-center absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 z-20"
    >
      <span className="relative grid place-items-center w-12 h-12 rounded-full bg-[var(--color-bg)] border-2 border-[var(--color-border)] shadow-[0_8px_24px_-8px_rgba(19,26,22,0.18)]">
        <span className="absolute inset-1.5 rounded-full bg-[var(--color-accent)]" />
        <span className="relative text-white font-bold text-[12px] tabular tracking-tighter">
          {String(index + 1).padStart(2, "0")}
        </span>
      </span>
    </motion.div>
  );
}

export function EndCap() {
  return (
    <div className="hidden lg:block absolute left-1/2 -translate-x-1/2 -bottom-2 z-10">
      <motion.div
        className="w-3.5 h-3.5 rounded-full bg-[var(--color-accent)]"
        initial={{ scale: 0, opacity: 0 }}
        whileInView={{ scale: 1, opacity: 1 }}
        viewport={{ once: true, margin: "-10%" }}
        transition={{ duration: 0.5, delay: 0.2 }}
      />
    </div>
  );
}
