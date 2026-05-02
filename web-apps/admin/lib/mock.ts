// Mock data — mirrors the Postgres schema in
// myapplication/backend/migrations/00001_auth_core.sql + 00002_app_domain.sql

import type { NutrientCode } from "./tokens";

export type Food = {
  id: string;
  name: string;
  brand?: string;
  category: string;
  servingSizeG: number;
  imageUrl?: string;
  barcode?: string;
  source: "seed" | "manual" | "user_submitted";
  verified: boolean;
  updatedAt: string;
  nutrients: { code: NutrientCode; name: string; amount: number; unit: string }[];
};

export type Nutrient = {
  id: string;
  code: NutrientCode | "Protein";
  name: string;
  unit: string;
  group: "vitamin" | "mineral" | "macro";
  driAdult: number;
  foodCount: number;
  updatedAt: string;
};

export type User = {
  id: string;
  email: string;
  role?: "user" | "admin";
  displayName: string;
  initials: string;
  sex: "female" | "male" | "other" | null;
  age: number | null;
  activity: string | null;
  status: "verified" | "unverified" | "suspended" | "pending_deletion";
  logs30d: number;
  lastActive: string | null;
  joined: string;
  platform: "iOS" | "Android" | "Web";
  recentLogs?: MealLog[];
  sessions?: {
    id: string;
    userAgent?: string;
    ip?: string;
    createdAt: string;
    expiresAt: string;
    revokedAt?: string;
  }[];
  reminderCount?: number;
  timezone?: string;
  units?: string;
  goals?: string[];
  allergens?: string[];
  safetyStatus?: string;
};

export type MealLog = {
  id: string;
  userId: string;
  userEmail: string;
  userInitials: string;
  loggedAt: string;
  meal: "breakfast" | "lunch" | "snack" | "dinner" | "other";
  items: string;
  topNutrients: NutrientCode[];
  flagged?: boolean;
};

export type ReminderTemplate = {
  id: string;
  title: string;
  body: string;
  trigger: string;
  audience: string;
  sent7d: number;
  active: boolean;
  updatedAt?: string;
};

export type Overview = {
  kpis: {
    activeUsers7d: { value: number; deltaPct: number };
    mealsLoggedToday: { value: number; deltaPct: number };
    foodsInCatalog: { value: number; addedThisWeek: number };
    pendingVerification: { value: number; over7days: number };
  };
  logsByDay: { day: string; logs: number }[];
  topNutrients: { code: NutrientCode; logs: number }[];
};

export const mock = {
  overview: {
    kpis: {
      activeUsers7d: { value: 3284, deltaPct: 12.4 },
      mealsLoggedToday: { value: 8941, deltaPct: 6.1 },
      foodsInCatalog: { value: 412, addedThisWeek: 9 },
      pendingVerification: { value: 17, over7days: 3 },
    },
    logsByDay: [
      { day: "Apr 11", logs: 6_842 },
      { day: "Apr 12", logs: 7_120 },
      { day: "Apr 13", logs: 7_380 },
      { day: "Apr 14", logs: 7_050 },
      { day: "Apr 15", logs: 7_910 },
      { day: "Apr 16", logs: 8_120 },
      { day: "Apr 17", logs: 8_402 },
      { day: "Apr 18", logs: 7_780 },
      { day: "Apr 19", logs: 8_550 },
      { day: "Apr 20", logs: 8_780 },
      { day: "Apr 21", logs: 9_010 },
      { day: "Apr 22", logs: 8_650 },
      { day: "Apr 23", logs: 8_840 },
      { day: "Apr 24", logs: 8_941 },
    ],
    topNutrients: [
      { code: "C",   logs: 12_402 },
      { code: "D",   logs: 9_184  },
      { code: "Fe",  logs: 8_772  },
      { code: "B12", logs: 7_310  },
      { code: "Ca",  logs: 6_841  },
      { code: "Mg",  logs: 5_902  },
      { code: "A",   logs: 5_488  },
      { code: "B9",  logs: 4_221  },
    ],
  } as Overview,

  foods: [
    { id: "018f0001", name: "Salmon, Atlantic",   category: "seafood",    servingSizeG: 100, source: "seed",          verified: true,  updatedAt: "2026-04-24T08:00:00Z", nutrients: [{code:"D",name:"Vitamin D",amount:13.0,unit:"mcg"},{code:"B12",name:"B12",amount:3.2,unit:"mcg"}] },
    { id: "018f0002", name: "Spinach, raw",       category: "vegetables", servingSizeG: 100, source: "seed",          verified: true,  updatedAt: "2026-04-23T08:00:00Z", nutrients: [{code:"K",name:"Vitamin K",amount:483.0,unit:"mcg"},{code:"B9",name:"Folate",amount:194.0,unit:"mcg"},{code:"A",name:"Vitamin A",amount:469.0,unit:"mcg"}] },
    { id: "018f0003", name: "Greek yogurt",       category: "dairy",      servingSizeG: 170, source: "seed",          verified: true,  updatedAt: "2026-04-22T08:00:00Z", nutrients: [{code:"Ca",name:"Calcium",amount:110.0,unit:"mg"},{code:"B12",name:"B12",amount:0.75,unit:"mcg"}] },
    { id: "018f0004", name: "Almonds, dry roast", category: "nuts",       servingSizeG: 28,  source: "seed",          verified: true,  updatedAt: "2026-04-22T08:00:00Z", nutrients: [{code:"Mg",name:"Magnesium",amount:270.0,unit:"mg"},{code:"Ca",name:"Calcium",amount:269.0,unit:"mg"}] },
    { id: "018f0005", name: "Sweet potato, baked",category: "vegetables", servingSizeG: 130, source: "seed",          verified: true,  updatedAt: "2026-04-21T08:00:00Z", nutrients: [{code:"A",name:"Vitamin A",amount:961.0,unit:"mcg"},{code:"C",name:"Vitamin C",amount:19.6,unit:"mg"}] },
    { id: "018f0006", name: "Lentils, cooked",    category: "legumes",    servingSizeG: 100, source: "seed",          verified: true,  updatedAt: "2026-04-20T08:00:00Z", nutrients: [{code:"B9",name:"Folate",amount:181.0,unit:"mcg"},{code:"Fe",name:"Iron",amount:3.3,unit:"mg"}] },
    { id: "018f0042", name: "Tempeh, organic",    brand: "Lightlife", category: "legumes", servingSizeG: 85, source: "manual",        verified: false, updatedAt: "2026-04-24T07:00:00Z", nutrients: [{code:"B12",name:"B12",amount:0.1,unit:"mcg"},{code:"Fe",name:"Iron",amount:2.7,unit:"mg"}] },
    { id: "018f0049", name: "Quinoa, cooked",     category: "grains",     servingSizeG: 185, source: "user_submitted",verified: false, updatedAt: "2026-04-24T05:00:00Z", nutrients: [{code:"Fe",name:"Iron",amount:1.5,unit:"mg"},{code:"Mg",name:"Magnesium",amount:64.0,unit:"mg"}] },
    { id: "018f0011", name: "Avocado, raw",       category: "fruits",     servingSizeG: 150, source: "seed",          verified: true,  updatedAt: "2026-04-19T08:00:00Z", nutrients: [{code:"K",name:"Vitamin K",amount:21.0,unit:"mcg"},{code:"B9",name:"Folate",amount:81.0,unit:"mcg"}] },
    { id: "018f0014", name: "Egg, large",         category: "dairy",      servingSizeG: 50,  source: "seed",          verified: true,  updatedAt: "2026-04-18T08:00:00Z", nutrients: [{code:"D",name:"Vitamin D",amount:2.0,unit:"mcg"},{code:"B12",name:"B12",amount:1.1,unit:"mcg"}] },
  ] satisfies Food[],

  nutrients: [
    { id: "n01", code: "A",   name: "Vitamin A",  unit: "mcg RAE", group: "vitamin", driAdult: 900,  foodCount: 74,  updatedAt: "2026-04-14" },
    { id: "n02", code: "C",   name: "Vitamin C",  unit: "mg",      group: "vitamin", driAdult: 90,   foodCount: 132, updatedAt: "2026-04-14" },
    { id: "n03", code: "D",   name: "Vitamin D",  unit: "mcg",     group: "vitamin", driAdult: 20,   foodCount: 38,  updatedAt: "2026-04-23" },
    { id: "n04", code: "E",   name: "Vitamin E",  unit: "mg",      group: "vitamin", driAdult: 15,   foodCount: 28,  updatedAt: "2026-04-12" },
    { id: "n05", code: "K",   name: "Vitamin K",  unit: "mcg",     group: "vitamin", driAdult: 120,  foodCount: 22,  updatedAt: "2026-04-12" },
    { id: "n06", code: "B6",  name: "Vitamin B6", unit: "mg",      group: "vitamin", driAdult: 1.7,  foodCount: 54,  updatedAt: "2026-04-12" },
    { id: "n07", code: "B9",  name: "Folate",     unit: "mcg DFE", group: "vitamin", driAdult: 400,  foodCount: 61,  updatedAt: "2026-04-12" },
    { id: "n08", code: "B12", name: "Vitamin B12",unit: "mcg",     group: "vitamin", driAdult: 2.4,  foodCount: 49,  updatedAt: "2026-04-12" },
    { id: "n09", code: "Fe",  name: "Iron",       unit: "mg",      group: "mineral", driAdult: 18,   foodCount: 88,  updatedAt: "2026-04-11" },
    { id: "n10", code: "Ca",  name: "Calcium",    unit: "mg",      group: "mineral", driAdult: 1000, foodCount: 74,  updatedAt: "2026-04-11" },
    { id: "n11", code: "Mg",  name: "Magnesium",  unit: "mg",      group: "mineral", driAdult: 400,  foodCount: 92,  updatedAt: "2026-04-11" },
    { id: "n12", code: "Zn",  name: "Zinc",       unit: "mg",      group: "mineral", driAdult: 11,   foodCount: 34,  updatedAt: "2026-04-11" },
  ] satisfies Nutrient[],

  users: [
    { id: "u01", email: "amelia@example.com",  displayName: "Amelia Marsh",  initials: "AM", sex: "female", age: 32, activity: "moderate", status: "verified",         logs30d: 184, lastActive: "2026-04-24T09:14:00Z", joined: "2026-01-14", platform: "iOS"     },
    { id: "u02", email: "ravi.k@example.com",  displayName: "Ravi Kapoor",   initials: "RK", sex: "male",   age: 41, activity: "active",   status: "verified",         logs30d: 92,  lastActive: "2026-04-24T09:00:00Z", joined: "2026-02-02", platform: "Android" },
    { id: "u03", email: "emma.o@example.com",  displayName: "Emma Olsen",    initials: "EO", sex: "female", age: 28, activity: "light",    status: "verified",         logs30d: 61,  lastActive: "2026-04-24T08:14:00Z", joined: "2026-01-22", platform: "iOS"     },
    { id: "u04", email: "jin@example.com",     displayName: "Jin Mei",       initials: "JM", sex: null,     age: null, activity: null,     status: "unverified",       logs30d: 3,   lastActive: "2026-04-21T12:00:00Z", joined: "2026-04-19", platform: "Android" },
    { id: "u05", email: "c.tovar@example.com", displayName: "Carlos Tovar",  initials: "CT", sex: "male",   age: 36, activity: "sedentary",status: "pending_deletion", logs30d: 0,   lastActive: "2026-04-03T10:00:00Z", joined: "2025-11-04", platform: "iOS"     },
    { id: "u06", email: "sara.o@example.com",  displayName: "Sara Okafor",   initials: "SO", sex: "female", age: 24, activity: "very_active", status: "verified",      logs30d: 248, lastActive: "2026-04-24T09:09:00Z", joined: "2025-12-30", platform: "iOS"     },
    { id: "u07", email: "dani@example.com",    displayName: "Dani Heinz",    initials: "DH", sex: "other",  age: 30, activity: "light",    status: "verified",         logs30d: 55,  lastActive: "2026-04-23T14:30:00Z", joined: "2026-02-14", platform: "Android" },
  ] satisfies User[],

  mealLogs: [
    { id: "l01", userId: "u01", userEmail: "amelia@example.com",  userInitials: "AM", loggedAt: "2026-04-24T09:14:00Z", meal: "breakfast", items: "Greek yogurt, Almonds dry roast",            topNutrients: ["Ca","Mg"]      },
    { id: "l02", userId: "u06", userEmail: "sara.o@example.com",  userInitials: "SO", loggedAt: "2026-04-24T09:09:00Z", meal: "snack",     items: "Avocado, raw",                                topNutrients: ["K","B9"]       },
    { id: "l03", userId: "u02", userEmail: "ravi.k@example.com",  userInitials: "RK", loggedAt: "2026-04-24T09:00:00Z", meal: "lunch",     items: "Lentils cooked, Sweet potato baked",          topNutrients: ["B9","Fe","A"]  },
    { id: "l04", userId: "u03", userEmail: "emma.o@example.com",  userInitials: "EO", loggedAt: "2026-04-24T08:52:00Z", meal: "lunch",     items: "Salmon Atlantic, Spinach raw",                topNutrients: ["D","B12","K"]  },
    { id: "l05", userId: "u07", userEmail: "dani@example.com",    userInitials: "DH", loggedAt: "2026-04-24T08:14:00Z", meal: "breakfast", items: "Egg large × 2, Avocado",                      topNutrients: ["D","K"]        },
    { id: "l06", userId: "u01", userEmail: "amelia@example.com",  userInitials: "AM", loggedAt: "2026-04-24T08:14:00Z", meal: "lunch",     items: "Salmon Atlantic, Sweet potato",               topNutrients: ["D","A"]        },
    { id: "l07", userId: "u04", userEmail: "jin@example.com",     userInitials: "JM", loggedAt: "2026-04-24T07:14:00Z", meal: "other",     items: "(no items)",                                  topNutrients: [], flagged: true },
  ] satisfies MealLog[],

  reminderTemplates: [
    { id: "r01", title: "Log breakfast",       body: "Time to log breakfast.",                            trigger: "Daily 09:00 local",        audience: "All users",          sent7d: 4_182, active: true  },
    { id: "r02", title: "Vitamin D gap",       body: "You've had 0 mcg of Vitamin D today.",              trigger: "If D < 25% by 18:00",      audience: "All users",          sent7d: 1_924, active: true  },
    { id: "r03", title: "Streak 7 days",       body: "You've logged 7 days in a row. Quietly impressive.",trigger: "On 7-day streak",          audience: "All users",          sent7d: 284,   active: true  },
    { id: "r04", title: "Iron low (female)",   body: "Low iron this week. Lentils, spinach are easy fixes.",trigger: "Weekly Sunday 19:00",    audience: "Female · adult",     sent7d: 1_341, active: true  },
    { id: "r05", title: "B12 plant-based",     body: "Your B12 has been low for 5 days.",                 trigger: "If B12 < 50% × 5d",        audience: "Diet: vegetarian",   sent7d: 412,   active: false },
    { id: "r06", title: "Welcome day-1",       body: "You're set up. Try logging your first meal.",       trigger: "24h after sign-up",        audience: "New users",          sent7d: 248,   active: true  },
    { id: "r07", title: "Inactive 14 days",    body: "It's been a while. Quick log?",                     trigger: "14 days inactive",         audience: "All users",          sent7d: 118,   active: false },
  ] satisfies ReminderTemplate[],
};
