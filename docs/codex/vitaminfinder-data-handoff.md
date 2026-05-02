# VitaminFinder Data Handoff

## Status
Completed on 2026-04-25.

## What Changed
- Extracted the bundled VitaminFinder dataset from `https://vitaminfinder.lovable.app/`.
- Added `backend/migrations/00006_vitaminfinder_percent_dv_sources.sql`.
  - 342 foods imported.
  - 27 nutrient profiles imported.
  - 7,637 non-zero percent-Daily-Value food nutrient rows imported.
  - Every imported food has a remote `image_url`.
- Added `backend/migrations/00007_dedupe_adult_dri_values.sql`.
  - Cleans duplicate adult DRI rows caused by nullable `sex`.
  - Adds a partial unique index for adult DRI rows where `sex IS NULL`.
- Updated the backend `/v1/foods` endpoint:
  - Supports `nutrient=<code>` for source ranking.
  - Returns `dri_percent` for nutrient-ranked results.
  - Merges raw `food_nutrients` and imported percent-DV profiles in food details.
- Updated Flutter:
  - Explore now browses vitamins, minerals, and macros.
  - Nutrient detail pages now support all 27 imported nutrients.
  - Top sources load from the live backend.
  - Food detail shows imported percent-DV profiles without treating them as raw USDA per-100g data.

## Important Data Note
VitaminFinder's own UI labels the food values as `% Daily Value`. It does not expose raw nutrient amounts or a reliable serving-size basis. To keep tracker math correct, those values are stored in `food_nutrient_daily_values`, not in `food_nutrients`.

USDA/raw nutrient amounts should still be added later for any imported food that needs accurate meal logging.

## Verification
- `go test ./...` passed.
- `flutter test` passed.
- `flutter analyze` passed.
- `flutter build web` passed.
- Applied migrations through version 7 against local Docker Postgres.
- Rebuilt/restarted local Docker API.
- Checked:
  - `GET /v1/foods?nutrient=C&limit=3`
  - `GET /v1/foods?nutrient=Kp&limit=3`
  - `GET /v1/foods/018f0000-0000-7000-8003-000000000001`
- Visual screenshots:
  - `build/visual-vitaminfinder-vitamin-c.png`
  - `build/visual-vitaminfinder-apple-detail.png`
  - `build/visual-vitaminfinder-app-home.png`

## Browser Use Note
Browser Use still failed because the Node REPL resolves `C:\nvm4w\nodejs\node.exe` at `v22.12.0`, while the plugin requires `>= v22.22.0`. Visual verification used bundled Node `v24.14.0` with Playwright and system Chrome instead.

## Reference Sources Used
- VitaminFinder source site: `https://vitaminfinder.lovable.app/`
- USDA FoodData Central API guide: `https://fdc.nal.usda.gov/api-guide`
- NIH ODS vitamin/mineral fact sheets list: `https://ods.od.nih.gov/factsheets/list-VitaminsMinerals/`
- FDA Daily Value explainer: `https://www.fda.gov/food/nutrition-facts-label/daily-value-nutrition-and-supplement-facts-labels`

## 2026-04-25 UI/Connectivity Follow-up
- Fixed the Android nutrient-detail crash by adding `FoodProvider.fetchFoods(...)`, a non-mutating catalog fetch that does not call `notifyListeners()`.
- Updated `VitaminDetailScreen` to use `fetchFoods(nutrient: code, limit: 8)` for top sources.
- Added bundled nutrient artwork via `NutrientArtwork`, so vitamins, minerals, and macros have local visual heroes instead of remote nutrient images.
- Added profile/preference wiring:
  - Flutter now parses editable `/me` fields: body details, goals, allergens, dietary pattern, units, timezone, and preferences.
  - `AuthProvider` now supports `PATCH /v1/me/profile` and `PATCH /v1/me/preferences`.
  - Appearance is stored in existing `preferences` JSON and drives `ThemeMode`.
- Added reminder wiring:
  - `ReminderProvider` supports `GET /v1/reminders`, `POST /v1/reminders`, and `DELETE /v1/reminders/{id}`.
  - The You page Reminders row now opens a functional reminder manager.
- Added app routes:
  - `/app/profile/goals`
  - `/app/profile/body`
  - `/app/profile/diet`
  - `/app/profile/reminders`
  - `/app/profile/units`
  - `/app/profile/appearance`
  - `/app/profile/about`
- Disabled always-on `DevicePreview`; it now only runs with `--dart-define=ENABLE_DEVICE_PREVIEW=true`.
- Backend `db.Me.Preferences` and `db.Profile.Preferences` now marshal as JSON instead of a base64 byte string.
- Verification after this follow-up:
  - `flutter test` passed.
  - `flutter analyze` passed.
  - `flutter build web` passed.
  - `flutter build apk --debug` passed.
  - `go test ./...` passed.

## Remaining Manual Check
- Run the Android emulator and open Vitamin A/C/D detail pages to confirm the crash no longer appears.
- Open the You page and tap every row to confirm navigation/save behavior against the live backend.
- Add and delete a reminder with Docker API running.
- Search `salmon`, `chicken`, and `almonds`; food cards should show real images when URLs load and a polished fallback when a URL fails.

## 2026-04-25 Search/Track/Visual Polish Follow-up
- Fixed the Search/Explore category-state leak:
  - `SearchScreen` now keeps its selected category and result list locally.
  - It calls `FoodProvider.fetchFoods(...)`, so opening Search from a category no longer mutates the shared Explore catalog.
  - Returning from Search no longer leaves Explore stuck on the previous category tag.
- Added `lib/core/models/visual_catalog.dart`:
  - Categories now have unique clinical/lifestyle image URLs, icons, and accent colors.
  - Vitamins, minerals, and macros now resolve through one nutrient visual catalog.
- Updated Explore:
  - Explore loads its own unfiltered catalog with `fetchFoods(limit: 100)`.
  - Category cards now use real unique imagery with a premium overlay treatment.
  - Nutrient chips now use icon-based `NutrientPill` components instead of plain letter badges.
- Updated shared UI:
  - Added `NutrientPill` for richer vitamin/mineral/macro tags.
  - Added `NVSelectField`, a rounded modal-sheet picker used instead of default Android dropdowns.
- Updated Track:
  - Track now keeps a selected date.
  - The week strip is tappable.
  - The calendar button opens `showDatePicker`, including older dates.
  - Dashboard totals, week totals, and meals refresh for the selected date.
- Updated food logging:
  - The food log sheet can now choose a meal date, so older days can be tracked directly.
  - Meal type selection now uses `NVSelectField`.
- Added meal inspection:
  - `showMealLogDetails(...)` opens a bottom sheet showing what was eaten, serving count, logged date, and delete action.
  - Track meal rows and Saved > Meals rows now open this detail sheet.
- Added tests:
  - `test/visual_catalog_test.dart`
  - `test/nutrition_provider_test.dart`
- Verification after this follow-up:
  - `flutter analyze` passed.
  - `flutter test` passed.
  - `go test ./...` passed.
  - `flutter build web` passed.
  - `flutter build apk --debug` passed.

## Current Remaining Manual Check
- Browser/visual smoke test the new Explore category imagery, nutrient pills, Track date picker, meal detail sheet, and `NVSelectField`.
- On Android emulator, confirm remote food/category images render with the existing network permissions.
- With Docker API running, add a meal to an older date, switch Track to that date, inspect the meal detail sheet, then delete it.
