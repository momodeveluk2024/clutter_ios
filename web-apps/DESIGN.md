# NV — Web Design System

Design language for the NV marketing site and admin dashboard.
Mirrors the Flutter app's tokens (`myapplication/lib/theme.dart`) so the three surfaces feel like one product.

---

## 1. Brand

**Name:** NV (Nutrient/Vitamin tracker)
**Voice:** clinical-warm. Confident, factual, never preachy. No exclamation points. No emoji.
**Tone of imagery:** muted produce photography, soft daylight, no stock-photo "fitness model" energy.

---

## 2. Color tokens

### Light (default)

| Token | Hex | Use |
|---|---|---|
| `--bg` | `#F6F7F3` | Page background |
| `--surface` | `#FFFFFF` | Cards, inputs, sheets |
| `--surface-muted` | `#EEF1EA` | Hover states, secondary chips |
| `--border` | `#E5E8DF` | Hairlines |
| `--text` | `#131A16` | Primary copy |
| `--text-muted` | `#5E6A63` | Secondary copy, captions |
| `--accent` | `#2F7D4A` | Brand green — primary CTA, links |
| `--accent-soft` | `#E6F1E9` | Accent background tint |
| `--accent-deep` | `#1E5A34` | Pressed/hover |
| `--warn` | `#C57420` | Warning |
| `--err` | `#B23A3A` | Error / destructive |
| `--ok` | `#2F7D4A` | Success (= accent) |

### Dark

| Token | Hex |
|---|---|
| `--bg` | `#0F1512` |
| `--surface` | `#18201C` |
| `--surface-muted` | `#1F2823` |
| `--border` | `#2A332D` |
| `--text` | `#F1F3EE` |
| `--text-muted` | `#9AA89F` |

### Nutrient hue map (use as data-color tags)

| Code | Fill | Soft bg | Nutrient |
|---|---|---|---|
| A | `#E88A3D` | `#FBEADB` | Vitamin A |
| C | `#2F7D4A` | `#E6F1E9` | Vitamin C |
| D | `#C79B1A` | `#F7EFD3` | Vitamin D |
| E | `#7A5CC0` | `#EBE6F6` | Vitamin E |
| K | `#3A6B88` | `#E1ECF2` | Vitamin K |
| B6 | `#B23A5C` | `#F4E0E6` | B6 |
| B12 | `#1E7A82` | `#DCECEE` | B12 |
| B9 | `#6B8E3A` | `#E9EFDA` | Folate |
| Fe | `#8A4B3D` | `#F1DFDB` | Iron |
| Zn | `#4A5B70` | `#DEE3EA` | Zinc |
| Mg | `#2B8079` | `#DAEDEA` | Magnesium |
| Ca | `#A07DBB` | `#ECE3F2` | Calcium |

---

## 3. Typography

**Font family:** Inter (Google Fonts). Fallback: `system-ui, -apple-system, Segoe UI, sans-serif`.

| Role | Size | Weight | Tracking |
|---|---|---|---|
| Display | `clamp(40px, 6vw, 72px)` | 700 | `-0.04em` |
| H1 | 40px | 700 | `-0.03em` |
| H2 | 28px | 700 | `-0.02em` |
| H3 | 20px | 600 | `-0.01em` |
| Body lg | 17px | 400 | `0` |
| Body | 14px | 400 | `0` |
| Caption | 12px | 500 | `0` |
| Eyebrow | 11px | 600 | `0.08em` UPPERCASE |

**Line-height:** 1.15 for headings, 1.55 for body. Always negative tracking on display & headings — this is a brand signal.

---

## 4. Spacing & radii

- Spacing scale: `4 / 8 / 12 / 16 / 24 / 32 / 48 / 64 / 96`
- Container max-width: `1200px` marketing, `1440px` dashboard
- Radii: `--r-sm: 8px`, `--r-md: 12px`, `--r-lg: 18px`, `--r-pill: 999px`
- Hairline shadow: `0 1px 0 rgba(19,26,22,0.04), 0 8px 32px -16px rgba(19,26,22,0.08)`

---

## 5. Components

**Button (primary):** `--accent` bg, white text, 14px height 44, radius `--r-pill`, no shadow, hover → `--accent-deep`.
**Button (ghost):** transparent bg, `--text` color, 1px `--border`, hover → `--surface-muted`.
**Input:** white bg, 1px `--border`, radius `--r-md`, focus → 2px `--accent` ring, no glow.
**Card:** `--surface` bg, 1px `--border`, radius `--r-lg`, padding 24.
**Chip:** `--surface-muted` bg, 11px eyebrow text, radius `--r-pill`, padding 4×10.
**Table:** zebra `--surface` / `--bg`, sticky 1px `--border` row separators, no vertical lines.

---

## 6. Marketing site IA

Single-page scroll:
1. **Nav** — logo left, anchor links (Features, How it works, Download), "Open dashboard" ghost CTA right
2. **Hero** — display headline + subhead + iOS/Android badge buttons + phone mockup
3. **Trust strip** — quiet line of "Built on USDA dietary references" etc.
4. **Features grid** — 6 cards (Track meals, Vitamin breakdown, Reminders, Goals, Favorites, Offline)
5. **How it works** — 3-step numbered diagram
6. **Screenshots** — phone-frame carousel
7. **Download** — large repeated CTAs with QR code
8. **Footer** — privacy, terms, contact, social

---

## 7. Admin dashboard IA

Sidebar (left, 240px collapsed to 64px):
- Overview (dashboard)
- Foods
- Nutrients (vitamins / minerals / macros)
- Meal Logs
- Users
- Reminders
- Settings

Topbar: breadcrumb + global search + user menu.
Content: max 1200px column on table pages; full-bleed on dashboard.

### Pages
| Route | Purpose |
|---|---|
| `/login` | admin sign-in |
| `/` | overview (KPIs + recent activity) |
| `/foods` | searchable table, bulk actions, "+ New food" |
| `/foods/:id` | edit food + nutrient amounts (per-100g) |
| `/nutrients` | nutrient & DRI table |
| `/nutrients/:id` | edit nutrient + DRI by life-stage |
| `/meal-logs` | global feed of user logs (read-only, moderation) |
| `/users` | users table with profile counts |
| `/users/:id` | profile, sessions, logs, danger zone |
| `/reminders` | system-wide reminder templates |
| `/settings` | admin profile, API keys, audit log |

---

## 8. Anti-patterns

- No drop shadows beyond the hairline shadow above. No glassmorphism, no gradients on surfaces.
- No emoji in product copy. No "Awesome!" microcopy.
- No accent color on more than one element per viewport (button OR chip OR icon — not all three).
- No icon-only nav items. Always pair icon + label.
- No more than 2 type sizes per card.
