import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  images: {
    remotePatterns: [
      { protocol: "https", hostname: "images.unsplash.com" },
      { protocol: "https", hostname: "plus.unsplash.com" },
    ],
  },
  // Hide the bottom-left dev badge that was overlapping mobile content
  devIndicators: false,
  experimental: {
    viewTransition: true,
  },
};

export default nextConfig;
