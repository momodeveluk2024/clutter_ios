import { principles } from "@/lib/copy";
import { Eyebrow } from "@/components/primitives/Eyebrow";
import { RevealOnView } from "@/components/motion/RevealOnView";

export default function AboutPage() {
  return (
    <>
      <header className="pt-40 pb-24">
        <div className="mx-auto max-w-3xl px-6">
          <RevealOnView>
            <Eyebrow>About Nutrimate</Eyebrow>
            <h1 className="display text-[clamp(48px,7vw,104px)] mt-6 leading-[0.95]">
              Honest tools for a quiet kind of health.
            </h1>
          </RevealOnView>
        </div>
      </header>

      <section className="py-20 border-y border-[var(--color-border)]">
        <div className="mx-auto max-w-3xl px-6">
          <RevealOnView>
            <blockquote className="display text-[clamp(28px,4vw,48px)] leading-[1.15] text-[var(--color-text)]">
              &ldquo;The best tracker is the one you forget you&apos;re using. Nutrimate is built to fade into your routine within a week.&rdquo;
            </blockquote>
            <p className="eyebrow mt-8">— Internal product principle</p>
          </RevealOnView>
        </div>
      </section>

      <section className="py-28 md:py-36">
        <div className="mx-auto max-w-7xl px-6">
          <RevealOnView>
            <Eyebrow>Three principles</Eyebrow>
            <h2 className="display-sans text-[clamp(36px,5vw,64px)] mt-5 mb-16 leading-[1.0] max-w-3xl">
              The decisions that shape every feature.
            </h2>
          </RevealOnView>

          <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
            {principles.map((p, i) => (
              <RevealOnView key={p.title} delay={i * 0.12}>
                <div className="border-t border-[var(--color-text)] pt-6">
                  <span className="tabular text-[40px] font-bold tracking-tighter text-[var(--color-accent)]">
                    0{i + 1}
                  </span>
                  <h3 className="text-2xl font-semibold tracking-tight mt-3 mb-3">
                    {p.title}
                  </h3>
                  <p className="text-[15px] text-[var(--color-text-muted)] leading-relaxed">
                    {p.body}
                  </p>
                </div>
              </RevealOnView>
            ))}
          </div>
        </div>
      </section>
    </>
  );
}
