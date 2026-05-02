import type { Metadata } from "next";
import { Inter, Fraunces } from "next/font/google";
import "./globals.css";
import { Nav } from "@/components/layout/Nav";
import { Footer } from "@/components/layout/Footer";
import { GrainOverlay } from "@/components/layout/GrainOverlay";
import { LenisProvider } from "@/components/layout/LenisProvider";

const inter = Inter({
  subsets: ["latin"],
  variable: "--font-inter",
  display: "swap",
});

const fraunces = Fraunces({
  subsets: ["latin"],
  variable: "--font-fraunces",
  display: "swap",
  axes: ["opsz"],
});

export const metadata: Metadata = {
  title: "Nutrimate — Know what's actually in your meals",
  description:
    "Nutrimate tracks the vitamins, minerals and macros in your meals using USDA dietary references. Available on iOS and Android.",
  metadataBase: new URL("https://nutrimate.app"),
  icons: { icon: "/logo.png", apple: "/logo.png" },
  openGraph: {
    title: "Nutrimate — Know what's actually in your meals",
    description:
      "A nutrition tracker built around vitamins and minerals — not just calories.",
    type: "website",
    images: ["/logo.png"],
  },
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en" className={`${inter.variable} ${fraunces.variable}`}>
      <body className="antialiased">
        <LenisProvider>
          <GrainOverlay />
          <Nav />
          <main>{children}</main>
          <Footer />
        </LenisProvider>
      </body>
    </html>
  );
}
