import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { join } from "node:path";

const root = process.cwd();
const read = (path) => readFileSync(join(root, path), "utf8");

const foodsPage = read("app/foods/page.tsx");
const nutrientsPage = read("app/nutrients/page.tsx");
const mealLogsPage = read("app/meal-logs/page.tsx");
const usersPage = read("app/users/page.tsx");
const overviewPage = read("app/page.tsx");
const sidebar = read("components/shell/Sidebar.tsx");
const nutrientPill = read("components/ui/NutrientPill.tsx");
const foodEditPage = read("app/foods/[id]/page.tsx");
const foodActions = read("app/foods/[id]/actions.ts");
const userDetailPage = read("app/users/[id]/page.tsx");
const remindersPage = read("app/reminders/page.tsx");
const api = read("lib/api.ts");

assert(!foodsPage.includes("of 412"), "Foods page must not show a hard-coded total count.");
assert(!sidebar.includes('badge: "412"'), "Sidebar must not show a hard-coded food count.");

for (const hardcoded of ["value={8941}", "value={52318}", "value={2.7}", "value={4}"]) {
  assert(!mealLogsPage.includes(hardcoded), `Meal logs page must not use hard-coded KPI ${hardcoded}.`);
}

for (const hardcoded of ["value={4182}", "value={3284}", "value={27}", "value={11}", "4,182 active"]) {
  assert(!usersPage.includes(hardcoded), `Users page must not use hard-coded KPI ${hardcoded}.`);
}

assert(!mealLogsPage.includes('href="#"'), "Meal log View/Review actions must navigate somewhere real.");
assert(!nutrientsPage.includes('href="#"'), "Nutrient action links must not be placeholders.");
assert(!nutrientsPage.includes("DRI table"), "Nutrients page must not show a static DRI editor with mock rows.");
assert(!overviewPage.includes('href="#"'), "Overview links must not be placeholders.");
assert(!overviewPage.includes("/foods/018f0049"), "Overview must not link to mock food ids.");
assert(!overviewPage.includes("/foods/018f0042"), "Overview must not link to mock food ids.");
assert(nutrientPill.includes("fallbackHue"), "Nutrient pills must have a fallback for backend nutrient codes outside the design palette.");

for (const [name, source] of [
  ["foods page", foodsPage],
  ["nutrients page", nutrientsPage],
  ["meal logs page", mealLogsPage],
  ["users page", usersPage],
  ["user detail page", userDetailPage],
  ["reminders page", remindersPage],
]) {
  assert(!source.includes('href="#"'), `${name} must not include placeholder href="#" actions.`);
}

for (const required of ["imageUrl", "uploadFoodImage", "createFood", "exportFoodsCsv"]) {
  assert(api.includes(required) || foodActions.includes(required) || foodEditPage.includes(required), `Food admin UI/API must include ${required}.`);
}

for (const required of ["verifyUser", "suspendUser", "deleteUser", "revokeUserSession"]) {
  assert(api.includes(required) || userDetailPage.includes(required), `User admin UI/API must include ${required}.`);
}

for (const required of ["createReminderTemplate", "updateReminderTemplate", "exportReminderTemplatesCsv"]) {
  assert(api.includes(required) || remindersPage.includes(required), `Reminder templates must include ${required}.`);
}

console.log("admin static regressions passed");
