import { features } from "@/lib/copy";
import { featuresPhotos } from "@/lib/images";
import { Eyebrow } from "@/components/primitives/Eyebrow";
import { RevealOnView } from "@/components/motion/RevealOnView";
import { ParallaxImage } from "@/components/motion/ParallaxImage";

export default function FeaturesPage() {
  return (
    <>
      <header className="pt-40 pb-20">
        <div className="mx-auto max-w-4xl px-6">
          <RevealOnView>
            <Eyebrow>Features</Eyebrow>
            <h1 className="display-sans text-[clamp(48px,7vw,96px)] mt-6 leading-[0.95]">
              Every detail of your nutrition, made calm and visible.
            </h1>
            <p className="mt-8 text-xl text-[var(--color-text-muted)] max-w-2xl leading-relaxed">
              Six things Nutrimate does well — and the design choices behind each one.
            </p>
          </RevealOnView>
        </div>
      </header>

      <div className="border-t border-[var(--color-border)]">
        {features.map((f, i) => {
          const photo = featuresPhotos[i];
          const flip = i % 2 === 1;
          return (
            <section key={f.title} className="py-24 md:py-32 border-b border-[var(--color-border)]">
              <div className="mx-auto max-w-7xl px-6 grid grid-cols-1 lg:grid-cols-2 gap-16 items-center">
                <RevealOnView className={flip ? "lg:order-2" : ""}>
                  <Eyebrow>0{i + 1} / 0{features.length}</Eyebrow>
                  <h2 className="display-sans text-[clamp(36px,4.5vw,56px)] mt-5 leading-[1.0]">
                    {f.title}
                  </h2>
                  <p className="mt-6 text-lg text-[var(--color-text-muted)] leading-relaxed max-w-md">
                    {f.body}
                  </p>
                </RevealOnView>
                <RevealOnView delay={0.15} className={flip ? "lg:order-1" : ""}>
                  <ParallaxImage
                    src={photo.url}
                    alt={photo.alt}
                    className="aspect-[4/5] w-full"
                  />
                </RevealOnView>
              </div>
            </section>
          );
        })}
      </div>
    </>
  );
}
