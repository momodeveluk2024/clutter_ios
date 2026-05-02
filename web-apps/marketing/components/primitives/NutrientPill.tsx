import { nutrientHues, type NutrientCode } from "@/lib/tokens";
import { cn } from "@/lib/utils";

type Props = {
  code: NutrientCode;
  size?: "sm" | "md" | "lg";
  className?: string;
};

const sizes = {
  sm: "h-6 min-w-7 px-2 text-[10px]",
  md: "h-8 min-w-9 px-3 text-[12px]",
  lg: "h-12 min-w-14 px-4 text-[16px]",
};

export function NutrientPill({ code, size = "md", className }: Props) {
  const hue = nutrientHues[code];
  return (
    <span
      className={cn(
        "inline-flex items-center justify-center rounded-full font-bold tracking-tight",
        sizes[size],
        className,
      )}
      style={{ backgroundColor: hue.bg, color: hue.fill }}
    >
      {code}
    </span>
  );
}
