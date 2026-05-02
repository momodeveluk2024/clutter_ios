"use client";

import Image from "next/image";
import { motion } from "motion/react";
import type { ReactNode } from "react";

/**
 * Six visually distinct ways to render a photo card. Each row of a vine
 * section picks a different treatment so adjacent rows never look the
 * same.
 */

export type TreatmentStyle =
  | "polaroid"
  | "block"
  | "circle"
  | "tilt"
  | "frame"
  | "stamp";

type Props = {
  treatment: TreatmentStyle;
  photo: { url: string; alt: string };
  side: "left" | "right";
  inView: boolean;
  delay?: number;
  caption?: ReactNode;
};

const easing = [0.2, 0.65, 0.3, 0.9] as const;

export function TreatmentImage({ treatment, photo, side, inView, delay = 0.5, caption }: Props) {
  const stampNumber =
    10 +
    (Array.from(photo.alt).reduce((sum, char) => sum + char.charCodeAt(0), 0) %
      90);

  switch (treatment) {
    /* ── 1. Polaroid: white frame, slight tilt, handwritten caption ── */
    case "polaroid":
      return (
        <motion.div
          initial={{ opacity: 0, scale: 0.92, rotate: 0 }}
          animate={inView ? { opacity: 1, scale: 1, rotate: side === "left" ? -3 : 3 } : {}}
          transition={{ duration: 0.85, ease: easing, delay }}
          className="bg-white px-3 pt-3 pb-8 rounded-[6px] shadow-[0_30px_80px_-30px_rgba(19,26,22,0.30)] max-w-[240px] mx-auto"
        >
          <div className="relative aspect-square overflow-hidden">
            <Image src={photo.url} alt={photo.alt} fill sizes="240px" className="object-cover" />
          </div>
          <p className="text-center mt-3 font-display italic text-[12px] text-[var(--color-text-muted)]">
            {photo.alt}
          </p>
        </motion.div>
      );

    /* ── 2. Color block: image with a soft accent rect offset behind it ── */
    case "block":
      return (
        <motion.div
          initial={{ opacity: 0, x: side === "left" ? -18 : 18 }}
          animate={inView ? { opacity: 1, x: 0 } : {}}
          transition={{ duration: 0.85, ease: easing, delay }}
          className="relative max-w-[260px] mx-auto"
        >
          <div
            className={`absolute w-full h-full rounded-[20px] bg-[var(--color-accent-soft)] ${
              side === "left" ? "-bottom-4 -right-4" : "-bottom-4 -left-4"
            }`}
          />
          <div className="relative aspect-[4/5] rounded-[20px] overflow-hidden border border-[var(--color-border)] bg-white shadow-[0_30px_80px_-30px_rgba(19,26,22,0.20)]">
            <Image src={photo.url} alt={photo.alt} fill sizes="260px" className="object-cover" />
          </div>
        </motion.div>
      );

    /* ── 3. Circle: round image with a halo ring ── */
    case "circle":
      return (
        <motion.div
          initial={{ opacity: 0, scale: 0.82 }}
          animate={inView ? { opacity: 1, scale: 1 } : {}}
          transition={{ duration: 0.9, ease: easing, delay }}
          className="relative max-w-[260px] mx-auto"
        >
          <div className="absolute -inset-3 rounded-full border-[3px] border-[var(--color-accent-soft)]" />
          <div className="absolute -inset-6 rounded-full border border-[var(--color-border)] opacity-50" />
          <div className="relative aspect-square rounded-full overflow-hidden shadow-[0_30px_80px_-30px_rgba(19,26,22,0.25)]">
            <Image src={photo.url} alt={photo.alt} fill sizes="260px" className="object-cover" />
          </div>
          {caption && (
            <p className="text-center mt-6 text-xs font-semibold text-[var(--color-text-muted)] tracking-wide uppercase">
              {caption}
            </p>
          )}
        </motion.div>
      );

    /* ── 4. Tilt: tall card, dramatic rotation ── */
    case "tilt":
      return (
        <motion.div
          initial={{ opacity: 0, scale: 0.92, rotate: 0 }}
          animate={inView ? { opacity: 1, scale: 1, rotate: side === "left" ? 5 : -5 } : {}}
          transition={{ duration: 0.95, ease: easing, delay }}
          className="relative max-w-[240px] mx-auto"
        >
          <div className="relative aspect-[3/4] rounded-[24px] overflow-hidden border border-[var(--color-border)] shadow-[0_40px_80px_-30px_rgba(19,26,22,0.30)]">
            <Image src={photo.url} alt={photo.alt} fill sizes="240px" className="object-cover" />
          </div>
        </motion.div>
      );

    /* ── 5. Frame: thick green accent border (like a mounted print) ── */
    case "frame":
      return (
        <motion.div
          initial={{ opacity: 0, y: 16 }}
          animate={inView ? { opacity: 1, y: 0 } : {}}
          transition={{ duration: 0.85, ease: easing, delay }}
          className="relative p-2 bg-[var(--color-accent)] rounded-[22px] max-w-[260px] mx-auto shadow-[0_30px_80px_-30px_rgba(19,26,22,0.25)]"
        >
          <div className="relative aspect-[4/5] rounded-[14px] overflow-hidden">
            <Image src={photo.url} alt={photo.alt} fill sizes="260px" className="object-cover" />
          </div>
          {/* Engraved label across the bottom of the frame */}
          <p className="text-center text-white py-2 eyebrow tracking-[0.2em]">
            Nutrimate - {stampNumber}
          </p>
        </motion.div>
      );

    /* ── 6. Stamp: dashed perforated edge, like a ticket / pharmacy sticker ── */
    case "stamp":
      return (
        <motion.div
          initial={{ opacity: 0, scale: 0.94 }}
          animate={inView ? { opacity: 1, scale: 1, rotate: side === "left" ? -2 : 2 } : {}}
          transition={{ duration: 0.85, ease: easing, delay }}
          className="relative bg-white p-3 max-w-[260px] mx-auto"
          style={{
            border: "2px dashed var(--color-text)",
            borderRadius: 6,
            boxShadow: "0 30px 80px -30px rgba(19,26,22,0.20)",
          }}
        >
          <div className="relative aspect-[4/5] rounded-[3px] overflow-hidden">
            <Image src={photo.url} alt={photo.alt} fill sizes="260px" className="object-cover" />
          </div>
          <p className="text-center mt-2 text-[10px] eyebrow tracking-[0.18em]">
            Stamped · Nutrimate
          </p>
        </motion.div>
      );
  }
}
