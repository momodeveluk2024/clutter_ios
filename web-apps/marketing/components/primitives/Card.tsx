"use client";

import { useRef, type ReactNode, type MouseEvent } from "react";
import { cn } from "@/lib/utils";

type Props = {
  children: ReactNode;
  className?: string;
  spotlight?: boolean;
};

export function Card({ children, className, spotlight = true }: Props) {
  const ref = useRef<HTMLDivElement>(null);

  const onMove = (e: MouseEvent<HTMLDivElement>) => {
    if (!spotlight) return;
    const el = ref.current;
    if (!el) return;
    const rect = el.getBoundingClientRect();
    el.style.setProperty("--mx", `${e.clientX - rect.left}px`);
    el.style.setProperty("--my", `${e.clientY - rect.top}px`);
  };

  return (
    <div
      ref={ref}
      onMouseMove={onMove}
      className={cn(
        "relative rounded-[18px] border border-[var(--color-border)] bg-[var(--color-surface)] p-7 lift overflow-hidden",
        className,
      )}
      style={{
        backgroundImage: spotlight
          ? "radial-gradient(360px circle at var(--mx, -100px) var(--my, -100px), rgba(47,125,74,0.06), transparent 60%)"
          : undefined,
      }}
    >
      {children}
    </div>
  );
}
