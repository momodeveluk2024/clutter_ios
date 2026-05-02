import { type ComponentPropsWithoutRef, type ReactNode } from "react";
import { cn } from "@/lib/utils";

export function Card({
  children,
  className,
  padded = true,
  ...props
}: {
  children: ReactNode;
  className?: string;
  padded?: boolean;
} & ComponentPropsWithoutRef<"div">) {
  return (
    <div
      {...props}
      className={cn(
        "rounded-[18px] border border-[var(--color-border)] bg-[var(--color-surface)]",
        padded && "p-6",
        className,
      )}
    >
      {children}
    </div>
  );
}
