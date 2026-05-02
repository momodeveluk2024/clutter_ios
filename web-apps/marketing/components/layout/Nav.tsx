"use client";

import { useState } from "react";
import Image from "next/image";
import Link from "next/link";
import { motion, useMotionValueEvent, useScroll } from "motion/react";
import { Button } from "../primitives/Button";
import { cn } from "@/lib/utils";

const links = [
  { href: "/features", label: "Features" },
  { href: "/about", label: "About" },
  { href: "/download", label: "Download" },
];

export function Nav() {
  const { scrollY } = useScroll();
  const [hidden, setHidden] = useState(false);
  const [scrolled, setScrolled] = useState(false);

  useMotionValueEvent(scrollY, "change", (cur) => {
    const prev = scrollY.getPrevious() ?? 0;
    setScrolled(cur > 16);
    if (cur > 200 && cur > prev) setHidden(true);
    else setHidden(false);
  });

  return (
    <motion.header
      initial={{ y: 0 }}
      animate={{ y: hidden ? -88 : 0 }}
      transition={{ duration: 0.4, ease: [0.2, 0.8, 0.2, 1] }}
      className={cn(
        "fixed top-0 inset-x-0 z-50 transition-[background,backdrop-filter,border-color] duration-300",
        scrolled
          ? "bg-[color-mix(in_srgb,var(--color-bg)_82%,transparent)] backdrop-saturate-150 backdrop-blur-md border-b border-[var(--color-border)]"
          : "bg-transparent border-b border-transparent",
      )}
    >
      <nav className="mx-auto max-w-7xl px-6 h-16 flex items-center justify-between">
        <Link href="/" className="flex items-center gap-2.5 group">
          <span className="relative w-9 h-9 grid place-items-center rounded-[10px] group-hover:scale-95 transition-transform">
            <Image
              src="/logo.png"
              alt="Nutrimate logo"
              width={36}
              height={36}
              className="object-contain"
              priority
            />
          </span>
          <span className="font-semibold tracking-tight">Nutrimate</span>
        </Link>

        <div className="hidden md:flex items-center gap-9">
          {links.map((l) => (
            <Link
              key={l.href}
              href={l.href}
              className="text-sm text-[var(--color-text)] hover:text-[var(--color-accent-deep)] transition-colors"
            >
              {l.label}
            </Link>
          ))}
        </div>

        <Button href="/download" variant="ghost" size="sm">
          Get Nutrimate →
        </Button>
      </nav>
    </motion.header>
  );
}
