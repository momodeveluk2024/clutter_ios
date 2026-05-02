import { type ReactNode } from "react";
import { cn } from "@/lib/utils";

type Variant = "default" | "accent" | "warn" | "ghost";

const variants: Record<Variant, string> = {
  default: "bg-[var(--color-surface-muted)] text-[var(--color-text)]",
  accent: "bg-[var(--color-accent-soft)] text-[var(--color-accent-deep)]",
  warn: "bg-[#FBEADB] text-[#8A4B20]",
  ghost: "bg-transparent text-[var(--color-text-muted)] border border-[var(--color-border)]",
};

export function Chip({
  children,
  variant = "default",
  className,
}: {
  children: ReactNode;
  variant?: Variant;
  className?: string;
}) {
  return (
    <span
      className={cn(
        "inline-flex items-center gap-1.5 h-7 px-3 rounded-full text-[11px] font-semibold tracking-wide",
        variants[variant],
        className,
      )}
    >
      {children}
    </span>
  );
}
