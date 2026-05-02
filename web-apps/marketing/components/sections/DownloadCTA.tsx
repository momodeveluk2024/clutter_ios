"use client";

import { motion } from "motion/react";
import { download } from "@/lib/copy";
import { MagneticButton } from "../motion/MagneticButton";
import { Eyebrow } from "../primitives/Eyebrow";

export function DownloadCTA() {
  return (
    <section id="download" className="relative py-32 md:py-44 bg-[var(--color-text)] text-[#F1F3EE] overflow-hidden">
      {/* Ambient orb */}
      <motion.div
        aria-hidden
        initial={{ opacity: 0, scale: 0.8 }}
        whileInView={{ opacity: 0.5, scale: 1 }}
        viewport={{ once: true }}
        transition={{ duration: 1.4 }}
        className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[760px] h-[760px] rounded-full"
        style={{ background: "radial-gradient(circle, rgba(47,125,74,0.25) 0%, transparent 65%)" }}
      />

      <div className="relative mx-auto max-w-3xl px-6 text-center">
        <Eyebrow className="!text-[#9AA89F]">{download.eyebrow}</Eyebrow>
        <h2 className="display-sans text-[clamp(40px,7vw,96px)] mt-6 leading-[0.95] text-[#F1F3EE]">
          {download.headline}
        </h2>
        <p className="mt-8 text-lg text-[#C8CFC9] leading-relaxed max-w-xl mx-auto">
          {download.sub}
        </p>

        <div className="mt-12 flex flex-wrap gap-3 justify-center">
          <MagneticButton
            href="#"
            className="inline-flex items-center gap-3 h-14 px-6 rounded-2xl bg-[#F1F3EE] text-[var(--color-text)] hover:bg-white transition-colors"
          >
            <svg width="22" height="22" viewBox="0 0 24 24" fill="currentColor">
              <path d="M17.05 20.28c-.98.95-2.05.8-3.08.35-1.09-.46-2.09-.48-3.24 0-1.44.62-2.2.44-3.06-.35C2.79 15.25 3.51 7.59 9.05 7.31c1.35.07 2.29.74 3.08.8 1.18-.24 2.31-.93 3.57-.84 1.51.12 2.65.72 3.4 1.8-3.12 1.87-2.38 5.98.48 7.13-.57 1.5-1.31 2.99-2.54 4.09zM12.03 7.25c-.15-2.23 1.66-4.07 3.74-4.25.29 2.58-2.34 4.5-3.74 4.25z" />
            </svg>
            <span className="text-left leading-tight">
              <small className="block text-[10px] opacity-60">Download on the</small>
              <strong className="block text-[15px] font-semibold">App Store</strong>
            </span>
          </MagneticButton>
          <MagneticButton
            href="#"
            className="inline-flex items-center gap-3 h-14 px-6 rounded-2xl bg-[#F1F3EE] text-[var(--color-text)] hover:bg-white transition-colors"
          >
            <svg width="20" height="22" viewBox="0 0 24 24" fill="currentColor">
              <path d="M3 2.5v19l8-9.5-8-9.5z" />
            </svg>
            <span className="text-left leading-tight">
              <small className="block text-[10px] opacity-60">Get it on</small>
              <strong className="block text-[15px] font-semibold">Google Play</strong>
            </span>
          </MagneticButton>
        </div>

        {/* QR placeholder */}
        <div className="mt-12 inline-block p-3 bg-[#F1F3EE] rounded-2xl">
          <div
            className="w-32 h-32 rounded-md"
            style={{
              backgroundImage:
                "repeating-conic-gradient(#F1F3EE 0% 25%, #131A16 0% 50%)",
              backgroundSize: "16px 16px",
            }}
          />
        </div>
        <p className="text-xs uppercase tracking-[0.2em] text-[#9AA89F] mt-4">Scan to download</p>
      </div>
    </section>
  );
}
