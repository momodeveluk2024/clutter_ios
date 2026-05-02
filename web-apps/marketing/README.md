# NV — Marketing site

Luxury, animated marketing site for NutriVita. Built on Next.js 16 + Tailwind v4 + Motion (Framer Motion).

## Run

```bash
cd web/marketing
npm install   # already done if you're reading this
npm run dev   # http://localhost:3000
```

## Stack

- **Next.js 16** App Router, React 19, TypeScript, Turbopack dev
- **Tailwind CSS v4** (CSS-first config in `app/globals.css`)
- **`motion`** (Framer Motion) for all animations
- **`lenis`** for smooth scroll
- **`lucide-react`** for icons
- **`next/font`** for Inter (sans) + Fraunces (display serif)
- **`next/image`** + curated Unsplash photography

## Pages

| Route | What |
|---|---|
| `/` | Landing — Hero, stats, marquee, **scroll-pinned nutrient reveal**, features grid, how-it-works, screenshots, dark download CTA |
| `/features` | Per-feature deep dive with parallax photography |
| `/about` | Brand story + three principles (Fraunces serif pull-quote) |
| `/download` | Platform-detected install page with QR code |

## Animation primitives

In `components/motion/`:

- `<SplitText>` — character-by-character text reveal
- `<RevealOnView>` — fade + Y-offset on scroll-into-view
- `<MagneticButton>` — cursor-tracked translate (capped 12px)
- `<CountUp>` — animated number tick-up
- `<Marquee>` — infinite horizontal scroll
- `<ParallaxImage>` — scroll-driven image translate

All respect `prefers-reduced-motion`.

## Design system

Lives in `app/globals.css` `@theme` block (Tailwind v4 token convention) and mirrors `web/DESIGN.md` and `myapplication/lib/theme.dart`. Shared with future admin app via `web/shared/tokens.ts`.

## Static reference

The original static HTML mockups in `web/marketing-site/` and `web/admin-dashboard/` are kept as a visual reference and are not connected to this Next.js app.
