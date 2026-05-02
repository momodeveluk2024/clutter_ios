# NV — Web

Static HTML/CSS mockups for the NV marketing site and admin dashboard.
Designed to live next to (not inside) the Flutter app at `myapplication/`.

## Open in browser

No build step. Open any `.html` file directly:

```
web/marketing-site/index.html       ← public landing page
web/admin-dashboard/login.html      ← admin sign-in (start here)
web/admin-dashboard/index.html      ← admin overview
```

The login button ("Sign in") jumps to the dashboard.

## Files

```
web/
├── DESIGN.md                       design system spec
├── shared/
│   └── styles.css                  tokens + primitives (used by every page)
├── marketing-site/
│   └── index.html                  landing
└── admin-dashboard/
    ├── _shell.css                  sidebar + topbar + table styles
    ├── _sidebar.html               reference markup for the sidebar
    ├── login.html
    ├── index.html                  overview / KPIs
    ├── foods.html                  CRUD list
    ├── food-edit.html              add / edit food + nutrients per 100g
    ├── nutrients.html              nutrient & DRI table
    ├── users.html
    ├── user-detail.html            profile, sessions, danger zone
    ├── meal-logs.html              moderation feed
    ├── reminders.html              templates + delivery health
    └── settings.html               profile / team / API keys / audit
```

## Design language

Mirrors `myapplication/lib/theme.dart`:

- Brand green `#2F7D4A` on warm off-white `#F6F7F3`
- Inter font, tight negative letter-spacing on headings
- Hairline borders, no drop shadows beyond a subtle hover lift
- Nutrient hue map matches `vitaminColors` in the Flutter theme

See [DESIGN.md](./DESIGN.md) for the full spec, including dark-mode tokens
and component rules.

## Next steps (when you want to ship for real)

1. **Marketing site** → drop the HTML/CSS into a static host (Cloudflare Pages, Netlify, Vercel). Replace placeholder store badges with real App Store / Play Store URLs.
2. **Admin dashboard** → port to a framework (`react-admin` or `Refine` recommended) and point at the Go backend's REST API. The current pages already mirror the database schema (`foods`, `food_nutrients`, `nutrients`, `dri_values`, `users`, `meal_logs`, `reminders`).
3. **Auth** → wire the admin login to a `POST /admin/login` endpoint on the backend with an `is_admin` role check.
