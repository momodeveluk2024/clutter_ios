import { type ReactNode } from "react";
import { cn } from "@/lib/utils";

export function Eyebrow({ children, className }: { children: ReactNode; className?: string }) {
  return (
    <span className={cn("eyebrow inline-flex items-center gap-2", className)}>
      <span className="block w-6 h-px bg-current opacity-40" />
      {children}
    </span>
  );
}
