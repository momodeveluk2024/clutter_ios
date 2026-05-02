"use client";

import { type ReactNode } from "react";
import { cn } from "@/lib/utils";

type Props = {
  items: string[];
  reverse?: boolean;
  className?: string;
  separator?: ReactNode;
};

export function Marquee({ items, reverse = false, className, separator }: Props) {
  const sep = separator ?? <span className="mx-6 text-ink-muted">·</span>;
  // Duplicate the list so the loop is seamless
  const doubled = [...items, ...items];

  return (
    <div className={cn("overflow-hidden whitespace-nowrap", className)}>
      <div className={cn("inline-flex", reverse ? "animate-marquee-reverse" : "animate-marquee")}>
        {doubled.map((it, i) => (
          <span key={i} className="inline-flex items-center text-2xl md:text-3xl font-medium tracking-tight text-ink">
            {it}
            {sep}
          </span>
        ))}
      </div>
    </div>
  );
}
