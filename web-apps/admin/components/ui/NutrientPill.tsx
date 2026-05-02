import { nutrientHues, type NutrientCode } from "@/lib/tokens";
import { cn } from "@/lib/utils";

const sizes = {
  xs: "h-5  min-w-6  px-1.5 text-[9px]",
  sm: "h-6  min-w-7  px-2   text-[10px]",
  md: "h-7  min-w-9  px-2.5 text-[11px]",
};

const fallbackHue = { fill: "#4A5565", bg: "#E8ECF2" };

export function NutrientPill({
  code,
  size = "sm",
  className,
}: {
  code: NutrientCode | string;
  size?: keyof typeof sizes;
  className?: string;
}) {
  const hue = nutrientHues[code as NutrientCode] ?? fallbackHue;

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
