"use client";

import { useRef } from "react";
import { motion, useScroll, useInView, useReducedMotion } from "motion/react";
import { features } from "@/lib/copy";
import { featuresPhotos } from "@/lib/images";
import { Eyebrow } from "../primitives/Eyebrow";
import { RevealOnView } from "../motion/RevealOnView";
import { Trunk, BranchSvg, StopBadge, EndCap } from "./TreeVine";
import { TreatmentImage, type TreatmentStyle } from "./TreatmentImage";

// Each row gets a different visual treatment. The cycle is chosen so adjacent
// rows always look different, and the section as a whole reads as varied.
const treatments: TreatmentStyle[] = [
  "polaroid",
  "block",
  "circle",
  "tilt",
  "frame",
  "stamp",
];

export function FeaturesGrid() {
  const total = features.length;

  const vineRef = useRef<HTMLDivElement>(null);
  const { scrollYProgress } = useScroll({
    target: vineRef,
    offset: ["start 0.85", "end 0.15"],
  });

  return (
    <section id="features" className="relative py-24 md:py-32">
      <div className="mx-auto max-w-7xl px-6">
        <RevealOnView>
          <div className="max-w-3xl mx-auto text-center mb-20 md:mb-32">
            <Eyebrow className="justify-center">What you get</Eyebrow>
            <h2
              className="display-sans mt-5 leading-[0.95] text-balance"
              style={{ fontSize: "clamp(36px, 6vw, 84px)", letterSpacing: "-0.03em" }}
            >
              Six things Nutrimate does,{" "}
              <span className="font-display italic font-semibold text-[var(--color-accent-deep)]">
                with care.
              </span>
            </h2>
            <p className="mt-8 text-base md:text-lg text-[var(--color-text-muted)] max-w-xl mx-auto leading-relaxed">
              Not another calorie counter. Each one fades into your routine within a week.
            </p>
          </div>
        </RevealOnView>

        {/* Tree */}
        <div ref={vineRef} className="relative">
          <Trunk progress={scrollYProgress} />

          <div className="relative">
            {features.map((f, i) => (
              <FeatureRow
                key={f.title}
                index={i}
                total={total}
                feature={f}
                photo={featuresPhotos[i] ?? featuresPhotos[0]}
                side={i % 2 === 0 ? "left" : "right"}
                treatment={treatments[i]}
              />
            ))}
          </div>

          <EndCap />
        </div>
      </div>
    </section>
  );
}

function FeatureRow({
  index, total, feature, photo, side, treatment,
}: {
  index: number;
  total: number;
  feature: { title: string; body: string };
  photo: { url: string; alt: string };
  side: "left" | "right";
  treatment: TreatmentStyle;
}) {
  const reduce = useReducedMotion();
  const ref = useRef<HTMLDivElement>(null);
  const inView = useInView(ref, { once: true, amount: 0.35 });

  return (
    <div
      ref={ref}
      className="relative grid grid-cols-1 lg:grid-cols-12 gap-y-6 gap-x-10 items-center"
      style={{ minHeight: "min(580px, 72vh)" }}
    >
      {/* Image — row-specific treatment */}
      <div className={`lg:col-span-4 ${side === "right" ? "lg:col-start-9" : "lg:col-start-1"}`}>
        <TreatmentImage
          treatment={treatment}
          photo={photo}
          side={side}
          inView={inView}
          delay={0.5}
        />
      </div>

      {/* Branch curve from trunk to image */}
      <BranchSvg side={side} inView={inView} delay={0.65} />

      {/* Stop badge on the trunk */}
      <StopBadge index={index} inView={inView} delay={0.4} />

      {/* Text — opposite side */}
      <motion.div
        initial={reduce ? { opacity: 1 } : { opacity: 0, y: 24 }}
        animate={inView ? { opacity: 1, y: 0 } : {}}
        transition={{ duration: 0.75, ease: [0.2, 0.65, 0.3, 0.9], delay: 0.7 }}
        className={`lg:col-span-5 relative ${
          side === "right" ? "lg:col-start-2 lg:row-start-1" : "lg:col-start-7"
        }`}
      >
        <Eyebrow>
          Stop {String(index + 1).padStart(2, "0")} of {String(total).padStart(2, "0")}
        </Eyebrow>

        <h3
          className="display-sans mt-5 leading-[0.95] text-balance"
          style={{ fontSize: "clamp(28px, 4vw, 56px)", letterSpacing: "-0.03em" }}
        >
          {feature.title}
        </h3>
        <p className="mt-6 text-base md:text-lg text-[var(--color-text-muted)] max-w-md leading-relaxed">
          {feature.body}
        </p>

        <div className="mt-8 flex items-center gap-3">
          <span className="w-12 h-px bg-[var(--color-accent)]" />
          <span className="eyebrow text-[var(--color-accent-deep)]">In the app</span>
        </div>
      </motion.div>

      {/* Mobile-only connector tick */}
      <span
        aria-hidden
        className="lg:hidden absolute left-1/2 -translate-x-1/2 -bottom-3 w-px h-6 bg-[var(--color-border)]"
      />
    </div>
  );
}
