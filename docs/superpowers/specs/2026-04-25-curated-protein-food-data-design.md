# Curated Protein Food Data Design

Date: 2026-04-25
Status: Approved by user for implementation

## Goal

Replace the placeholder seed food experience with a curated, accurate, real-data protein-focused catalog. The first version should stay small enough to maintain by hand, load quickly, and avoid pulling a huge USDA dataset into the repository.

## Data Source

Use USDA FoodData Central as the nutrition source. Prefer Foundation Foods or SR Legacy entries for whole/minimally processed foods because those records are stable and suitable for per-100g nutrient values. Store the visible source string on each food so the app can show where the data came from.

## Scope

Seed roughly 15-25 high-protein foods across animal, seafood, dairy, legumes, soy, nuts/seeds, and grains. Include protein for every food and include the strongest relevant micronutrients already supported by the app: vitamin D, B12, iron, calcium, magnesium, vitamin C, vitamin A, folate, and vitamin K.

Add real image URLs for each food. Images should be stable remote URLs suitable for app display, with the backend returning the URL through both list and detail endpoints. The Flutter app should show the image when present and keep the existing placeholder as a fallback.

## Backend Design

Add an optional `image_url` column to `foods`.

Update backend food structs and queries so `image_url` appears in:

- `GET /foods`
- `GET /foods/{id}`
- barcode detail responses if applicable

Update seed data in a new migration rather than rewriting old migrations. The migration should upsert the curated foods and nutrient values using fixed UUIDs, set `source` to USDA/FDC-specific text, set `verified = true`, and attach image URLs.

Keep the existing CSV import tool compatible. It can leave `image_url` null unless later extended.

## Flutter Design

Extend `FoodSummary` and `FoodDetail` with `imageUrl`.

Replace `PhotoPlaceholder` usage on search, favorites, and food detail with a reusable food image widget. The widget should:

- render `Image.network` when a URL exists
- crop consistently with `BoxFit.cover`
- fall back to `PhotoPlaceholder` on empty URL or image load failure
- keep current dimensions/radius behavior so layouts do not shift

## Tests And Verification

Add focused tests where practical:

- Dart model parsing handles `image_url`
- Go/backend tests or migration checks cover `image_url` response fields if existing server tests make this feasible

Run:

- `flutter test`
- `flutter analyze`
- backend Go tests for changed backend packages

If the app can be run locally, inspect the UI in the in-app browser or with Flutter web to confirm real images display and fallback remains sane.

## Handoff Rule

Maintain `docs/codex/curated-protein-data-handoff.md` after each meaningful phase. Another Codex should be able to open that file and know current status, changed files, remaining tasks, commands already run, and any blockers.
