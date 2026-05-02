"use client";

import { motion, useReducedMotion } from "motion/react";

type Props = {
  children: string;
  className?: string;
  delay?: number;
  stagger?: number;
  as?: "h1" | "h2" | "h3" | "p" | "span" | "div";
};

/**
 * Word-by-word reveal. Each word slides up from below the line; we never
 * split chars across word boundaries so words can never wrap mid-character
 * on narrow viewports (the bug that made the hero say "actua / lly").
 *
 * Mobile-safe and visually equivalent to a char reveal at speed.
 */
export function SplitText({
  children,
  className,
  delay = 0,
  stagger = 0.045,
  as = "h1",
}: Props) {
  const reduce = useReducedMotion();
  const Tag = motion[as];

  if (reduce) {
    return <Tag className={className}>{children}</Tag>;
  }

  // Preserve explicit \n line breaks
  const lines = children.split("\n");

  let runningWordIdx = 0;

  return (
    <Tag className={className} aria-label={children}>
      {lines.map((line, li) => {
        const words = line.split(" ");
        return (
          <span key={li} className="block">
            {words.map((word, wi, arr) => {
              const i = runningWordIdx++;
              return (
                <span
                  key={wi}
                  // inline-block + overflow-hidden creates the "mask" the
                  // word slides out of; whitespace-nowrap prevents breaks
                  className="inline-block overflow-hidden align-bottom"
                  style={{ whiteSpace: "nowrap" }}
                >
                  <motion.span
                    className="inline-block"
                    initial={{ y: "110%" }}
                    animate={{ y: "0%" }}
                    transition={{
                      duration: 0.65,
                      delay: delay + i * stagger,
                      ease: [0.2, 0.65, 0.3, 0.9],
                    }}
                  >
                    {word}
                    {wi < arr.length - 1 ? " " : ""}
                  </motion.span>
                </span>
              );
            })}
          </span>
        );
      })}
    </Tag>
  );
}
