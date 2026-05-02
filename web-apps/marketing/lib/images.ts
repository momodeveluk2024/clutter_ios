// Curated Unsplash photography matching DESIGN.md tone:
// "muted produce photography, soft daylight, no stock-photo 'fitness model' energy."
// All photo IDs verified via Unsplash search.

export type FoodPhoto = {
  id: string;
  url: string;
  alt: string;
  photographer: string;
  photographerUrl: string;
};

const food = (id: string, alt: string, photographer: string, handle: string): FoodPhoto => ({
  id,
  url: `https://images.unsplash.com/photo-${id}?w=1600&q=80&auto=format&fit=crop`,
  alt,
  photographer,
  photographerUrl: `https://unsplash.com/@${handle}`,
});

// ---------- Food / produce ----------
export const photos: FoodPhoto[] = [
  food("1490645935967-10de6ba17061", "Bowl of greens, grains and salmon",        "Ella Olsson",       "ellaolsson"),
  food("1567620905732-2d1ec7ab7445", "Healthy bowl with seeds and avocado",      "Ella Olsson",       "ellaolsson"),
  food("1540189549336-e6e99c3679fe", "Plate of vegetables and chickpeas",        "Anna Pelzer",       "annapelzer"),
  food("1565958011703-44f9829ba187", "Salmon fillet on dark plate",              "Caroline Attwood",  "carolineattwood"),
  food("1490818387583-1baba5e638af", "Wood table breakfast bowl",                "Brooke Lark",       "brookelark"),
  food("1494390248081-4e521a5940db", "Avocado halved on table",                  "Thought Catalog",   "thoughtcatalog"),
  food("1518569656558-1f25e69d93d7", "Spinach leaves on white",                  "Pille R Priske",    "pillepriske"),
  food("1508061253366-f7da158b6d46", "Almonds in a bowl",                        "Rachael Gorjestani","rachaelgorj"),
  food("1505252585461-04db1eb84625", "Berries close-up",                         "Henry Be",          "henry_be"),
  food("1506976785307-8732e854ad03", "Sliced sweet potato",                      "Louis Hansel",      "louishansel"),
  food("1547592180-85f173990554",   "Vegetable salad bowls",                    "Anna Pelzer",       "annapelzer"),
  food("1512621776951-a57141f2eefd", "Vegetable salad close",                    "Ella Olsson",       "ellaolsson"),
];

// ---------- Vitamin / supplement / capsule ----------
// Verified Unsplash search results — high-end photography of pills, capsules,
// blister packs. Used for the "actually about vitamins" sections.
export const vitaminPhotos: FoodPhoto[] = [
  food("1614643458308-656e13a14a2f", "Orange and yellow oval vitamin",           "Royyan Haifdz",     "royyanhaifdz"),
  food("1569914511576-2fe7e52c7043", "Translucent capsules in studio light",     "Andres Siimon",     "andressiimon"),
  food("1565071783280-719b01b29912", "Amber gel capsules close-up",              "Michele Blackwell", "micheleblackwell"),
  food("1577368211130-4bbd0181ddf0", "Person holding vitamin pills",             "Volodymyr Hryshchenko","arvitalyaart"),
  food("1624362772755-4d5843e67047", "Brown and yellow tablets scattered",       "Leohoho",           "leohoho"),
  food("1577401132921-cb39bb0adcff", "Colorful blister packs of tablets",        "Volodymyr Hryshchenko","arvitalyaart"),
];

// helpers for sections
export const heroPhoto       = photos[3];                  // salmon
export const featuresPhotos  = [photos[0], photos[1], photos[5], photos[7], photos[2], photos[4]];
export const galleryPhotos   = [photos[6], photos[10], photos[8], photos[11]];
export const screenshotPhotos = [photos[1], photos[0], photos[2]];
export const proteinNatureGallery = [photos[3], photos[0], photos[7], photos[5], photos[2], photos[6]];

// vitamin imagery — used by the new VitaminGallery section
export const vitaminGallery  = vitaminPhotos;
export const heroCapsule     = vitaminPhotos[2]; // amber gel — warmest, lifts the hero corner

// Meal items rotated through the phone mockup's "today" list. Each entry
// pairs an Unsplash food photo with a realistic logged-meal serving.
export type PhoneMeal = {
  id: string;
  name: string;
  amount: string;
  photo: string;
  alt: string;
};

export const phoneMealPool: PhoneMeal[] = [
  { id: "salmon",    name: "Salmon, Atlantic", amount: "120 g · 264 kcal", photo: photos[3].url, alt: photos[3].alt },
  { id: "spinach",   name: "Spinach, raw",     amount: "45 g · 11 kcal",   photo: photos[6].url, alt: photos[6].alt },
  { id: "yogurt",    name: "Greek yogurt",     amount: "170 g · 100 kcal", photo: photos[4].url, alt: photos[4].alt },
  { id: "almonds",   name: "Almonds",          amount: "30 g · 173 kcal",  photo: photos[7].url, alt: photos[7].alt },
  { id: "avocado",   name: "Avocado",          amount: "1 medium · 234 kcal", photo: photos[5].url, alt: photos[5].alt },
  { id: "berries",   name: "Berries, mixed",   amount: "100 g · 57 kcal",  photo: photos[8].url, alt: photos[8].alt },
];
