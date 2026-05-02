import { Hero } from "@/components/sections/Hero";
import { TrustStrip } from "@/components/sections/TrustStrip";
import { StatsCounter } from "@/components/sections/StatsCounter";
import { MarqueeRow } from "@/components/sections/MarqueeRow";
import { VitaminGallery } from "@/components/sections/VitaminGallery";
import { NutrientReveal } from "@/components/sections/NutrientReveal";
import { FeaturesGrid } from "@/components/sections/FeaturesGrid";
import { HowItWorks } from "@/components/sections/HowItWorks";
import { Screenshots } from "@/components/sections/Screenshots";
import { DownloadCTA } from "@/components/sections/DownloadCTA";

export default function Home() {
  return (
    <>
      <Hero />
      <TrustStrip />
      <StatsCounter />
      <MarqueeRow />
      <VitaminGallery />
      <NutrientReveal />
      <FeaturesGrid />
      <HowItWorks />
      <Screenshots />
      <DownloadCTA />
    </>
  );
}
