"use client";

import { useRef } from "react";
import Image from "next/image";
import { motion, useScroll, useTransform, useReducedMotion } from "motion/react";
import { cn } from "@/lib/utils";

type Props = {
  src: string;
  alt: string;
  className?: string;
  intensity?: number;
  priority?: boolean;
  rounded?: boolean;
};

export function ParallaxImage({
  src,
  alt,
  className,
  intensity = 60,
  priority = false,
  rounded = true,
}: Props) {
  const reduce = useReducedMotion();
  const ref = useRef<HTMLDivElement>(null);
  const { scrollYProgress } = useScroll({
    target: ref,
    offset: ["start end", "end start"],
  });
  const y = useTransform(scrollYProgress, [0, 1], reduce ? [0, 0] : [intensity, -intensity]);
  const scale = useTransform(scrollYProgress, [0, 0.5, 1], reduce ? [1, 1, 1] : [1.06, 1.0, 1.06]);

  return (
    <div
      ref={ref}
      className={cn("relative overflow-hidden", rounded && "rounded-2xl", className)}
    >
      <motion.div className="absolute inset-0" style={{ y, scale }}>
        <Image
          src={src}
          alt={alt}
          fill
          sizes="(max-width: 768px) 100vw, 50vw"
          className="object-cover"
          priority={priority}
        />
      </motion.div>
    </div>
  );
}
