# NV — Admin Dashboard

Heavy-data admin app for NutriVita. Built on Next.js 16 + Tailwind v4 + Motion + Recharts.

## Run

```bash
cd web/admin
npm install     # already done if you're reading this
npm run dev     # http://localhost:3002
```

The marketing site lives on port **3001** so both can run side by side.

## Backend wiring

The admin reads from `process.env.NEXT_PUBLIC_API_URL` (default `http://localhost:8080/v1` — your Go backend).

- If the API responds, real data is shown.
- If the API is unreachable (e.g. backend not running), each call **falls back to mock data** in `lib/mock.ts` so the dashboard stays browseable.
- Mock fallbacks log a single line to the browser console: `[api] mock fallback for /foods`.

To override the API URL: copy `.env.local.example` to `.env.local` and set `NEXT_PUBLIC_API_URL`.

## Routes

| Route | What |
|---|---|
| `/login` | Admin sign-in (animated, two-pane layout) |
| `/` | Overview — animated KPIs, area chart of meal logs, recent activity, top nutrients |
| `/foods` | Filterable, paginated foods table (staggered row entry) |
| `/foods/[id]` | Edit food + per-100g nutrients table + danger zone |
| `/nutrients` | Nutrients table + DRI editor for the selected nutrient |
| `/users` | Users table with KPIs + status filters |
| `/users/[id]` | User profile, tabs, sessions, danger zone |
| `/meal-logs` | Read-only feed of all user meal logs (moderation view) |
| `/reminders` | Reminder templates table + APNs/FCM delivery health |
| `/settings` | Profile / team / API keys / integrations / audit log / danger zone |

## Animation patterns

- **`<KpiCard>`** — number counts up from 0 on `useInView` (eased)
- **`<Table>`** — `<TRow>` staggers entry with a small per-row delay
- **`<LogsChart>`** — Recharts `Area` with built-in animation, brand-tinted gradient
- **Sidebar active state** — `motion.span` with `layoutId="active-pill"` slides between routes
- **Login** — left pane fades in + right gradient pane has an ambient orb fade-in

All animations honor `prefers-reduced-motion`.

## Design language

Mirrors `web/DESIGN.md` and the Flutter app:

- Brand green `#2F7D4A` on warm `#F6F7F3` background
- Inter font, tabular numerals on every number
- Hairline 1px borders, no drop shadows beyond a subtle hover lift
- Nutrient hue map (A=orange, D=yellow, Fe=brown…) reused on pills + chart accents
- Tokens live in `app/globals.css` `@theme` block (Tailwind v4 convention)

## Stack

- **Next.js 16.2.4** App Router, React 19, TypeScript, Turbopack
- **Tailwind CSS v4** (CSS-first config)
- **`motion`** v12 — animations
- **`recharts`** v2 — charts
- **`lucide-react`** — icons
- **`next/font`** — Inter
