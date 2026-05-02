# Nutrimate — Product

## Register

**brand** — the marketing site's design IS the product impression. Strict editorial standards apply.

The admin dashboard at `web-apps/admin/` is **product** register and should be evaluated separately.

## What it is

A nutrition tracker built around vitamins and minerals, not calories. Logs meals, scores intake against USDA FoodData Central + NIH dietary reference intake (DRI) values by life stage, and shows which nutrients the user is consistently missing.

Native iOS and Android. The website ships as a marketing surface for the apps and a small admin dashboard for the team.

## Users (marketing site visitor)

Adults already using or shopping for a nutrition tracker who are tired of calorie-only apps. They want to know whether they're getting enough iron, B12, magnesium — not whether they ate "too much." They are skeptical of:

- Streaks, badges, gamified shame
- Hand-wavy wellness claims without sourcing
- Calorie-first UIs (MyFitnessPal, Lose It, Cronometer's data density)
- Apps that resell their data

Many are women in pregnancy / postpartum, vegetarians / vegans worried about B12 / iron, athletes tracking electrolytes, and people working with a dietitian who told them to track a specific nutrient.

## Brand voice

**Clinical-warm.** Confident, factual, never preachy.

- No exclamation points
- No emoji in product copy
- No "Awesome!" / "Let's go!" microcopy
- No fitness-coach urgency
- No em dashes (use commas, colons, semicolons, periods, or parentheses)
- Every word earns its place; no restated headings
- Cite sources when making nutrition claims (USDA, NIH)

## Anti-references

What the marketing site must not look or sound like:

- **MyFitnessPal / Lose It** — calorie-shame, gamified streaks, neon cards
- **Cronometer** — data-dump tables and 1990s information density
- **Noom** — chatty therapy-speak, paywall maze
- **Generic "wellness" SaaS-cream** — pastel gradients, "Live your best life", soft round everything
- **Crypto / fintech reflex** — neon-on-black, navy-and-gold
- **Healthcare reflex** — white + teal sterile, stock-photo doctors
- **Hero-metric template** — big number / small label / supporting stats SaaS cliché (currently in StatsCounter.tsx — fix)

## Strategic principles

1. **Honest numbers.** Show what was eaten and what's missing. Don't gamify nutrition.
2. **Calm interface.** No flashing badges, no streak guilt. The best tracker is one you forget you're using.
3. **Sourced, not invented.** USDA FoodData Central for foods, NIH DRI for targets. Cite both.
4. **Privacy-first.** No ads, no resale. End-to-end encrypted sync.
5. **One accent.** Brand green is restrained — it carries CTAs, focused affordances, and live data. Not decoration.

## Surfaces

| Path | Surface | Register |
|---|---|---|
| `web-apps/marketing/` | Next.js marketing site (the live one) | brand |
| `web-apps/admin/` | Next.js admin dashboard | product |
| `web-apps/marketing-site/index.html` | Legacy static mockup | superseded |
| `web-apps/admin-dashboard/*.html` | Legacy static mockups | superseded |
| `myapplication/lib/` | Flutter mobile app | product (separate review) |

The current impeccable pass scopes to **`web-apps/marketing/`** only.
