"use client";

import { motion } from "motion/react";
import { type ComponentPropsWithoutRef, type ReactNode } from "react";
import { cn } from "@/lib/utils";

export function Table({ children, className }: { children: ReactNode; className?: string }) {
  return (
    <div className={cn("rounded-[18px] border border-[var(--color-border)] bg-[var(--color-surface)] overflow-hidden", className)}>
      <table className="w-full text-[13px]">{children}</table>
    </div>
  );
}

export function THead({ children }: { children: ReactNode }) {
  return (
    <thead>
      <tr className="border-b border-[var(--color-border)]">{children}</tr>
    </thead>
  );
}

export function TH({ children, className }: { children: ReactNode; className?: string }) {
  return (
    <th
      className={cn(
        "text-left px-4 py-3 text-[10px] font-bold tracking-[0.08em] uppercase text-[var(--color-text-muted)] bg-[var(--color-surface)]",
        className,
      )}
    >
      {children}
    </th>
  );
}

export function TBody({ children }: { children: ReactNode }) {
  return <tbody>{children}</tbody>;
}

// Animated row — staggered fade-in on mount
export function TRow({
  children,
  index = 0,
  href,
}: {
  children: ReactNode;
  index?: number;
  href?: string;
}) {
  return (
    <motion.tr
      initial={{ opacity: 0, y: 6 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ delay: Math.min(index * 0.025, 0.4), duration: 0.35, ease: [0.2, 0.65, 0.3, 0.9] }}
      className={cn(
        "border-b border-[var(--color-border)] last:border-b-0 transition-colors",
        href && "hover:bg-[var(--color-surface-muted)] cursor-pointer",
      )}
      onClick={href ? () => (window.location.href = href) : undefined}
    >
      {children}
    </motion.tr>
  );
}

export function TD({
  children,
  className,
  ...props
}: { children: ReactNode; className?: string } & ComponentPropsWithoutRef<"td">) {
  return <td {...props} className={cn("px-4 py-3.5 align-middle", className)}>{children}</td>;
}
