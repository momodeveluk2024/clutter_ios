import { cn } from "@/lib/utils";

const palette = ["#2F7D4A", "#7A5CC0", "#3A6B88", "#B23A5C", "#8A4B3D", "#2B8079", "#C79B1A"];

function colorFor(seed: string) {
  let h = 0;
  for (let i = 0; i < seed.length; i++) h = (h * 31 + seed.charCodeAt(i)) >>> 0;
  return palette[h % palette.length];
}

const sizes = {
  xs: "w-6  h-6  text-[9px]",
  sm: "w-8  h-8  text-[11px]",
  md: "w-10 h-10 text-[12px]",
  lg: "w-16 h-16 text-[20px]",
};

export function Avatar({
  initials,
  seed,
  size = "sm",
  className,
}: {
  initials: string;
  seed?: string;
  size?: keyof typeof sizes;
  className?: string;
}) {
  return (
    <div
      className={cn("grid place-items-center rounded-full text-white font-bold", sizes[size], className)}
      style={{ background: colorFor(seed ?? initials) }}
    >
      {initials}
    </div>
  );
}
