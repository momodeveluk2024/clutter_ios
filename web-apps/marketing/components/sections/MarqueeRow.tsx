import { Marquee } from "../motion/Marquee";
import { foodMarquee } from "@/lib/copy";

export function MarqueeRow() {
  return (
    <section className="py-8 border-y border-[var(--color-border)] bg-[var(--color-surface-muted)] overflow-hidden">
      <div className="space-y-6">
        <Marquee items={foodMarquee} />
        <Marquee items={[...foodMarquee].reverse()} reverse />
      </div>
    </section>
  );
}
