import { type ReactNode } from "react";
import { cn } from "@/lib/utils";

type Variant = "default" | "accent" | "warn" | "err" | "muted";

const variants: Record<Variant, string> = {
  default: "bg-[var(--color-surface-muted)] text-[var(--color-text)]",
  accent:  "bg-[var(--color-accent-soft)] text-[var(--color-accent-deep)]",
  warn:    "bg-[var(--color-warn-soft)]   text-[#8A4B20]",
  err:     "bg-[var(--color-err-soft)]    text-[#8A2828]",
  muted:   "bg-transparent text-[var(--color-text-muted)] border border-[var(--color-border)]",
};

export function Chip({
  children,
  variant = "default",
  dot = false,
  className,
}: {
  children: ReactNode;
  variant?: Variant;
  dot?: boolean;
  className?: string;
}) {
  return (
    <span
      className={cn(
        "inline-flex items-center gap-1.5 h-6 px-2.5 rounded-full text-[11px] font-semibold",
        variants[variant],
        className,
      )}
    >
      {dot && <span className="w-1.5 h-1.5 rounded-full bg-current" />}
      {children}
    </span>
  );
}
