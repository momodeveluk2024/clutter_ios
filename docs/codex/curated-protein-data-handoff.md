# Curated Protein Data Handoff

Last updated: 2026-04-25 16:11 Asia/Baghdad

## User Request

The user wants the recommended curated dataset approach: accurate USDA-sourced protein-food data, real internet image URLs, and all needed supporting info. They also asked for this file to be kept updated so another Codex can resume without starting over if context/token runs out.

## Current Approach

Use a curated high-protein dataset rather than importing the full USDA dataset. Add backend support for food image URLs, seed real verified foods/nutrients, then update Flutter models and UI to render those images with placeholder fallback.

## Progress

- [x] Inspected current Flutter app and backend.
- [x] Confirmed existing seed data lives in `backend/migrations/00002_app_domain.sql`.
- [x] Confirmed Flutter currently has no `image_url` field and uses `PhotoPlaceholder`.
- [x] Wrote design spec: `docs/superpowers/specs/2026-04-25-curated-protein-food-data-design.md`.
- [x] Wrote implementation plan: `docs/superpowers/plans/2026-04-25-curated-protein-food-data.md`.
- [x] Added Dart model red test, then implemented `imageUrl` parsing in `lib/core/models/food.dart`.
- [x] Added backend red test for `image_url` JSON, then implemented `ImageURL` in `backend/internal/db/catalog.go`.
- [x] Added backend schema/migration `image_url` support in `backend/migrations/00005_curated_protein_food_images.sql`.
- [x] Added curated USDA-sourced seed migration with 18 high-protein foods and supported nutrient values.
- [x] Added Flutter image URL model parsing.
- [x] Replaced food placeholders with `FoodPhoto` real-image widget in search, favorites, and detail.
- [x] Ran verification commands.
- [x] Built Flutter web successfully.
- [x] Completed browser/app visual check with bundled Playwright and Chrome.
- [x] Rebuilt/recreated Docker `api` and `migrate` containers so Docker API on `8080` uses the latest code.

## Files Changed By This Task

- `docs/superpowers/specs/2026-04-25-curated-protein-food-data-design.md`: durable design/spec.
- `docs/superpowers/plans/2026-04-25-curated-protein-food-data.md`: resumable implementation plan.
- `docs/codex/curated-protein-data-handoff.md`: this handoff file.
- `test/food_model_test.dart`: model parsing tests for `image_url`.
- `lib/core/models/food.dart`: added `imageUrl` parsing to `FoodSummary` and `FoodDetail`.
- `lib/widgets.dart`: added `FoodPhoto` network image widget with placeholder fallback.
- `lib/screens/search.dart`: uses `FoodPhoto` for food result thumbnails.
- `lib/screens/favorites.dart`: uses `FoodPhoto` for favorite food thumbnails.
- `lib/screens/food_detail.dart`: uses `FoodPhoto` for detail hero image.
- `backend/internal/db/catalog_image_url_test.go`: backend JSON contract test.
- `backend/internal/db/catalog.go`: returns `image_url` from list/detail SQL.
- `backend/internal/server/catalog.go`: accepts optional `image_url` in create-food request validation.
- `backend/migrations/00005_curated_protein_food_images.sql`: adds `image_url` and seeds 18 curated USDA protein foods.

## Important Existing Files

- `backend/migrations/00002_app_domain.sql`: initial nutrient, DRI, food, and food nutrient seed data.
- `backend/internal/db/catalog.go`: food structs and list/detail SQL.
- `backend/internal/server/catalog.go`: food HTTP handlers and create request.
- `lib/core/models/food.dart`: Flutter food models.
- `lib/screens/search.dart`: search result food cards.
- `lib/screens/favorites.dart`: favorite food cards.
- `lib/screens/food_detail.dart`: detail hero image placeholder.
- `lib/widgets.dart`: `PhotoPlaceholder` lives here and should remain as fallback.

## Notes

- Repository root is `C:/Users/PC/Downloads/he mamosta kollage/applicationfluttter/myapplication`.
- The worktree already had many modified/untracked files before this task. Do not revert unrelated user changes.
- `rg.exe` failed with "Access is denied" in this environment, so use PowerShell `Get-ChildItem` and `Select-String` if needed.
- USDA FoodData Central says its data is public domain/CC0 and requests citation. Source page: https://fdc.nal.usda.gov/

## Commands Run

- `git status --short`
- `Get-ChildItem -Recurse`
- `Get-Content` on app/backend files
- Web research against USDA FoodData Central pages
- `flutter test test/food_model_test.dart` failed as expected before model support.
- `flutter test test/food_model_test.dart` passed after `imageUrl` parsing.
- `go test ./internal/db -run TestFoodSummaryIncludesImageURLInJSON` failed as expected before backend support.
- `go test ./internal/db -run TestFoodSummaryIncludesImageURLInJSON` passed after adding `ImageURL`.
- Downloaded USDA SR Legacy JSON from `https://fdc.nal.usda.gov/fdc-datasets/FoodData_Central_sr_legacy_food_json_2018-04.zip` to temp and extracted nutrient values for selected FDC IDs.
- `go test ./...` from `backend` passed after migration/backend changes.
- `flutter test` passed after Flutter image UI changes.
- `flutter analyze` initially reported two `unnecessary_underscores` info lints in `lib/widgets.dart`; fixed by naming the `errorBuilder` parameters.
- `dart format lib/core/models/food.dart lib/widgets.dart lib/screens/search.dart lib/screens/favorites.dart lib/screens/food_detail.dart test/food_model_test.dart` ran after UI edits.
- `flutter analyze` passed after formatting/fix: "No issues found!".
- `flutter test` passed after formatting/fix: "All tests passed!".
- `flutter build web` passed and produced `build/web`.
- Started `flutter run -d web-server --web-port 3000 --web-hostname 127.0.0.1`; server logged `lib\main.dart is being served at http://127.0.0.1:3000`.
- Stopped the background Flutter web-server processes after verification.
- `docker compose up -d postgres` confirmed `nutrivita-postgres` was running and healthy.
- `go run ./cmd/migrate up` applied `00005_curated_protein_food_images.sql` and migrated the database to version 5.
- A stale API was already listening on `8080`, so a temporary current-code API was started on `8081` for initial endpoint verification.
- `GET http://localhost:8081/v1/foods?q=chicken&limit=5` returned curated foods with `image_url`.
- `GET http://localhost:8081/v1/foods/{salmon-cooked-id}` returned `source = USDA FoodData Central FDC 175168`, a non-null `image_url`, and 10 nutrients.
- Built Flutter web with `--dart-define=NUTRIVITA_API_URL=http://localhost:8081/v1`, served it on `127.0.0.1:3002`, and used bundled Playwright + local Chrome for visual screenshots.
- Visual screenshots created:
  - `build/visual-search-salmon.png`
  - `build/visual-search-chicken.png`
  - `build/visual-food-detail.png`
- `visual-search-chicken.png` shows chicken and chickpeas result cards with rendered images.
- `visual-food-detail.png` shows the cooked salmon detail page with rendered hero image, USDA source, verified metric, and nutrient breakdown.
- After the user confirmed Docker could be used, ran `docker compose --profile api up -d --build`, which rebuilt and recreated Docker `api`/`migrate`.
- `GET http://localhost:8080/v1/foods?q=chicken&limit=5` from the Docker API returned curated chicken/chickpeas with non-null `image_url`.
- `GET http://localhost:8080/v1/foods/{salmon-cooked-id}` from the Docker API returned USDA source, non-null `image_url`, and 10 nutrients.
- Temporary local API on `8081` and static web server on `3002` were stopped after verification.

## Known Limitations / Follow-Up

- Browser Use plugin could not be used because the Node REPL runtime reported Node `v22.12.0` but requires `>= v22.22.0`. Visual verification was completed with bundled Playwright using bundled Node `v24.14.0` and local Chrome instead.
- The backend migration has now been applied against the live local Docker Postgres database.
- Image URLs are remote Unsplash image URLs. The Flutter `FoodPhoto` widget falls back to `PhotoPlaceholder` if any remote image fails.

## Next Step

No remaining verification step for the curated protein/image feature. Optional next step: commit these changes or keep extending the catalog/admin tools.
