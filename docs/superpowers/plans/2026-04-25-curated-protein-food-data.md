# Curated Protein Food Data Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a small verified USDA-sourced high-protein food catalog with real image URLs, and render those images in the Flutter app.

**Architecture:** Store image URLs as nullable backend food metadata, return them through existing food list/detail APIs, and parse them in existing Flutter models. Keep the curated nutrition data in a new additive migration so older migrations remain stable.

**Tech Stack:** Flutter/Dart, Go, PostgreSQL migrations with goose, FoodData Central nutrition source, network images in Flutter.

---

## File Structure

- Modify `backend/internal/db/catalog.go`: add `ImageURL` to response structs and SQL scan paths.
- Modify `backend/internal/server/catalog.go`: accept optional `image_url` on user-created foods without requiring it.
- Create `backend/migrations/00005_curated_protein_food_images.sql`: add `foods.image_url` and upsert curated foods/nutrient values.
- Create `test/food_model_test.dart`: Dart model parsing tests for `image_url`.
- Modify `lib/core/models/food.dart`: add `imageUrl` to `FoodSummary` and `FoodDetail`.
- Modify `lib/widgets.dart`: add `FoodPhoto` wrapper using `Image.network` with placeholder fallback.
- Modify `lib/screens/search.dart`, `lib/screens/favorites.dart`, and `lib/screens/food_detail.dart`: render `FoodPhoto`.
- Update `docs/codex/curated-protein-data-handoff.md` after each task.

## Curated Food Set

Use 18 foods, all stored per 100g nutrient amounts:

- Chicken breast, cooked, roasted
- Turkey breast, cooked, roasted
- Beef top sirloin, lean, broiled
- Pork chop, lean, broiled
- Tuna, light, canned in water, drained
- Salmon, Atlantic, cooked, dry heat
- Shrimp, cooked
- Egg, whole, cooked, hard-boiled
- Greek yogurt, plain, nonfat
- Cottage cheese, lowfat
- Lentils, cooked
- Chickpeas, cooked
- Black beans, cooked
- Tofu, firm
- Tempeh
- Almonds, dry roasted
- Peanut butter, smooth
- Quinoa, cooked

For each row, include `Protein` and any meaningful supported micronutrients from the app's nutrient list: `D`, `B12`, `Fe`, `Ca`, `Mg`, `C`, `A`, `B9`, `K`.

## Task 1: Dart Model Test For Image URLs

**Files:**
- Create: `test/food_model_test.dart`
- Modify later: `lib/core/models/food.dart`

- [ ] **Step 1: Write the failing test**

Create `test/food_model_test.dart` with tests asserting `FoodSummary.fromJson` and `FoodDetail.fromJson` expose `imageUrl` from `image_url`.

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/food_model_test.dart`

Expected: FAIL with Dart compile errors that `imageUrl` is not defined.

- [ ] **Step 3: Implement minimal model support**

Add nullable `String? imageUrl` to `FoodSummary`, parse `json['image_url'] as String?`, pass it through `FoodDetail` with `super.imageUrl`, and parse it in `FoodDetail.fromJson`.

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/food_model_test.dart`

Expected: PASS.

- [ ] **Step 5: Update handoff**

Mark Task 1 complete in `docs/codex/curated-protein-data-handoff.md`.

## Task 2: Backend Response Test For Image URLs

**Files:**
- Create: `backend/internal/db/catalog_image_url_test.go`
- Modify later: `backend/internal/db/catalog.go`

- [ ] **Step 1: Write a focused compile-time JSON contract test**

Create a test in package `db` that constructs `FoodSummary{ImageURL: &imageURL}`, marshals it, and asserts JSON contains `image_url`.

- [ ] **Step 2: Run test to verify it fails**

Run from `backend`: `go test ./internal/db -run TestFoodSummaryIncludesImageURLInJSON`

Expected: FAIL to compile because `FoodSummary.ImageURL` does not exist.

- [ ] **Step 3: Implement minimal backend structs and SQL**

Add `ImageURL *string json:"image_url,omitempty"` to `FoodSummary`; update `ListFoods` and `GetFoodDetail` SELECT/scan order to include `f.image_url`.

- [ ] **Step 4: Run test to verify it passes**

Run from `backend`: `go test ./internal/db -run TestFoodSummaryIncludesImageURLInJSON`

Expected: PASS.

- [ ] **Step 5: Update handoff**

Mark Task 2 complete in `docs/codex/curated-protein-data-handoff.md`.

## Task 3: Backend Schema And Curated Seed Migration

**Files:**
- Create: `backend/migrations/00005_curated_protein_food_images.sql`
- Modify: `backend/internal/server/catalog.go`

- [ ] **Step 1: Query USDA FoodData Central**

Use `https://api.nal.usda.gov/fdc/v1/foods/search?api_key=DEMO_KEY` or the current USDA download to fetch per-100g values for the curated foods. Record the selected FDC IDs and the supported nutrient values in the migration comments/handoff.

- [ ] **Step 2: Add migration**

Create a goose migration that adds `foods.image_url`, upserts the 18 food rows with fixed UUIDs and image URLs, and upserts `food_nutrients` values for supported nutrients. Down migration deletes the fixed curated IDs and drops `image_url`.

- [ ] **Step 3: Update create-food request compatibility**

In `backend/internal/server/catalog.go`, add `ImageURL *string json:"image_url" validate:"omitempty,url,max=500"` to `createFoodRequest`. User-created foods can remain null for this task.

- [ ] **Step 4: Verify backend tests still pass**

Run from `backend`: `go test ./...`

Expected: PASS or integration test skipped unless `NUTRIVITA_RUN_INTEGRATION=1`.

- [ ] **Step 5: Update handoff**

Record migration status and USDA source notes in `docs/codex/curated-protein-data-handoff.md`.

## Task 4: Flutter FoodPhoto Widget And UI Use

**Files:**
- Modify: `lib/widgets.dart`
- Modify: `lib/screens/search.dart`
- Modify: `lib/screens/favorites.dart`
- Modify: `lib/screens/food_detail.dart`

- [ ] **Step 1: Add reusable image widget**

In `lib/widgets.dart`, add a `FoodPhoto` widget below `PhotoPlaceholder`. It should trim the URL, render `Image.network` with `BoxFit.cover` when present, and use `PhotoPlaceholder` for empty URLs and `errorBuilder`.

- [ ] **Step 2: Replace search result placeholder**

In `lib/screens/search.dart`, replace `PhotoPlaceholder(label: food.category, height: 56, width: 56, radius: 12)` with `FoodPhoto(label: food.name, imageUrl: food.imageUrl, height: 56, width: 56, radius: 12)`.

- [ ] **Step 3: Replace favorites placeholder**

In `lib/screens/favorites.dart`, replace `PhotoPlaceholder(label: food.category, height: 52, width: 52, radius: 12)` with `FoodPhoto(label: food.name, imageUrl: food.imageUrl, height: 52, width: 52, radius: 12)`.

- [ ] **Step 4: Replace detail hero placeholder**

In `lib/screens/food_detail.dart`, replace `PhotoPlaceholder(label: food.name, height: 260, radius: 0, tone: 'warm')` with `FoodPhoto(label: food.name, imageUrl: food.imageUrl, height: 260, radius: 0, tone: 'warm')`.

- [ ] **Step 5: Verify Flutter tests**

Run: `flutter test`

Expected: PASS.

- [ ] **Step 6: Update handoff**

Mark Task 4 complete.

## Task 5: Full Verification And Visual Check

**Files:**
- Update: `docs/codex/curated-protein-data-handoff.md`

- [ ] **Step 1: Run static analysis**

Run: `flutter analyze`

Expected: no new errors.

- [ ] **Step 2: Run backend tests**

Run from `backend`: `go test ./...`

Expected: PASS or integration test skipped.

- [ ] **Step 3: Run Flutter web**

Run: `flutter run -d chrome --web-port 3000`

Expected: app starts on `http://localhost:3000`.

- [ ] **Step 4: Browser visual check**

Use Browser Use plugin to open `http://localhost:3000`, search for `salmon` or `chicken`, and confirm food list/detail image areas show network photos or graceful fallback.

- [ ] **Step 5: Final handoff update**

Update handoff with changed files, verification commands and results, remaining risk, and the next recommended task.

## Self-Review

- Spec coverage: backend image field, seed data, Flutter models, UI fallback, tests, and handoff are covered.
- Type consistency: backend JSON uses `image_url`; Dart uses `imageUrl`.
