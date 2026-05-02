"use client";

import { useSyncExternalStore } from "react";
import { motion } from "motion/react";
import { Eyebrow } from "@/components/primitives/Eyebrow";
import { MagneticButton } from "@/components/motion/MagneticButton";
import { RevealOnView } from "@/components/motion/RevealOnView";

type Platform = "ios" | "android" | "other";

function detectPlatform(): Platform {
  if (typeof navigator === "undefined") return "other";
  const ua = navigator.userAgent;
  if (/iPad|iPhone|iPod/.test(ua)) return "ios";
  if (/android/i.test(ua)) return "android";
  return "other";
}

function subscribeToPlatform(checkForChanges: () => void) {
  window.addEventListener("focus", checkForChanges);
  return () => window.removeEventListener("focus", checkForChanges);
}

export default function DownloadPage() {
  const platform = useSyncExternalStore(
    subscribeToPlatform,
    detectPlatform,
    () => "other",
  );

  return (
    <>
      <header className="pt-40 pb-12">
        <div className="mx-auto max-w-3xl px-6 text-center">
          <RevealOnView>
            <Eyebrow>Get Nutrimate</Eyebrow>
            <h1 className="display-sans text-[clamp(48px,7vw,96px)] mt-6 leading-[0.95]">
              Free. No account required to try.
            </h1>
            <p className="mt-8 text-lg text-[var(--color-text-muted)] max-w-xl mx-auto leading-relaxed">
              Available on iPhone, Android phones and tablets. Sync across devices when you create an account.
            </p>
          </RevealOnView>
        </div>
      </header>

      <section className="pb-24">
        <div className="mx-auto max-w-3xl px-6 flex flex-col items-center">
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.4 }}
            className="flex flex-wrap gap-3 justify-center mt-6"
          >
            <MagneticButton
              href="#"
              className={`inline-flex items-center gap-3 h-16 px-8 rounded-2xl bg-[var(--color-text)] text-white hover:bg-black transition-colors ${platform === "ios" ? "ring-4 ring-[var(--color-accent-soft)]" : ""}`}
            >
              <svg width="24" height="24" viewBox="0 0 24 24" fill="currentColor">
                <path d="M17.05 20.28c-.98.95-2.05.8-3.08.35-1.09-.46-2.09-.48-3.24 0-1.44.62-2.2.44-3.06-.35C2.79 15.25 3.51 7.59 9.05 7.31c1.35.07 2.29.74 3.08.8 1.18-.24 2.31-.93 3.57-.84 1.51.12 2.65.72 3.4 1.8-3.12 1.87-2.38 5.98.48 7.13-.57 1.5-1.31 2.99-2.54 4.09zM12.03 7.25c-.15-2.23 1.66-4.07 3.74-4.25.29 2.58-2.34 4.5-3.74 4.25z" />
              </svg>
              <span className="text-left leading-tight">
                <small className="block text-[11px] opacity-60">Download on the</small>
                <strong className="block text-[16px] font-semibold">App Store</strong>
              </span>
            </MagneticButton>
            <MagneticButton
              href="#"
              className={`inline-flex items-center gap-3 h-16 px-8 rounded-2xl bg-[var(--color-text)] text-white hover:bg-black transition-colors ${platform === "android" ? "ring-4 ring-[var(--color-accent-soft)]" : ""}`}
            >
              <svg width="22" height="24" viewBox="0 0 24 24" fill="currentColor">
                <path d="M3 2.5v19l8-9.5-8-9.5z" />
              </svg>
              <span className="text-left leading-tight">
                <small className="block text-[11px] opacity-60">Get it on</small>
                <strong className="block text-[16px] font-semibold">Google Play</strong>
              </span>
            </MagneticButton>
          </motion.div>

          <motion.div
            initial={{ opacity: 0, scale: 0.9 }}
            animate={{ opacity: 1, scale: 1 }}
            transition={{ delay: 0.6, duration: 0.7 }}
            className="mt-12 p-3 bg-[var(--color-surface)] border border-[var(--color-border)] rounded-2xl"
          >
            <div
              className="w-40 h-40 rounded-md"
              style={{
                backgroundImage: "repeating-conic-gradient(#F6F7F3 0% 25%, #131A16 0% 50%)",
                backgroundSize: "20px 20px",
              }}
            />
          </motion.div>
          <p className="text-xs uppercase tracking-[0.2em] text-[var(--color-text-muted)] mt-3">
            Scan to download · {platform === "ios" ? "We see you're on iOS" : platform === "android" ? "We see you're on Android" : "iOS or Android"}
          </p>
        </div>
      </section>

      <section className="py-24 border-t border-[var(--color-border)]">
        <div className="mx-auto max-w-4xl px-6 grid grid-cols-1 md:grid-cols-3 gap-12">
          <RevealOnView>
            <h3 className="eyebrow mb-3">Requirements</h3>
            <p className="text-sm text-[var(--color-text-muted)] leading-relaxed">
              iOS 16+ or Android 10+. 80 MB free storage. Internet for sync, optional for tracking.
            </p>
          </RevealOnView>
          <RevealOnView delay={0.1}>
            <h3 className="eyebrow mb-3">What&apos;s new in v1.4</h3>
            <p className="text-sm text-[var(--color-text-muted)] leading-relaxed">
              Adaptive reminders, weekly nutrient trends, faster barcode scanning.
            </p>
          </RevealOnView>
          <RevealOnView delay={0.2}>
            <h3 className="eyebrow mb-3">Privacy</h3>
            <p className="text-sm text-[var(--color-text-muted)] leading-relaxed">
              No ads, no third-party trackers. Local-first storage. End-to-end encryption on sync.
            </p>
          </RevealOnView>
        </div>
      </section>
    </>
  );
}
