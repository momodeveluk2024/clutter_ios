import { CountUp } from "../motion/CountUp";
import { RevealOnView } from "../motion/RevealOnView";
import { stats } from "@/lib/copy";

export function StatsCounter() {
  return (
    <section className="py-12 md:py-16">
      <div className="mx-auto max-w-7xl px-6">
        <RevealOnView className="grid grid-cols-1 md:grid-cols-3 gap-8 md:gap-16">
          {stats.map((s) => (
            <div key={s.label} className="text-left md:text-left">
              <div className="display text-[clamp(56px,8vw,120px)] text-[var(--color-text)] leading-none flex items-baseline">
                <CountUp to={s.value} decimals={s.decimals ?? 0} />
                <span className="ml-1 text-[var(--color-accent)]">{s.suffix}</span>
              </div>
              <p className="mt-3 text-sm text-[var(--color-text-muted)] uppercase tracking-wider font-semibold">
                {s.label}
              </p>
            </div>
          ))}
        </RevealOnView>
      </div>
    </section>
  );
}
