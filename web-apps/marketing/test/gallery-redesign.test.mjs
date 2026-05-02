import { readFileSync } from "node:fs";
import { test } from "node:test";
import assert from "node:assert/strict";

const gallerySource = readFileSync(
  new URL("../components/sections/VitaminGallery.tsx", import.meta.url),
  "utf8",
);
const imageSource = readFileSync(new URL("../lib/images.ts", import.meta.url), "utf8");

test("gallery uses nature and protein imagery instead of supplement imagery", () => {
  assert.match(imageSource, /proteinNatureGallery/);
  assert.match(gallerySource, /proteinNatureGallery/);
  assert.doesNotMatch(gallerySource, /vitaminGallery/);
});

test("gallery does not bring back the removed full-height tree or glow filter", () => {
  assert.doesNotMatch(gallerySource, /function TreeSvg/);
  assert.doesNotMatch(gallerySource, /id="glow"/);
  assert.doesNotMatch(gallerySource, /filter="url\(#glow\)"/);
});

test("gallery renders an interactive single-screen vitamin tree", () => {
  // Six branches connect a central hub to six fruit nodes.
  assert.match(gallerySource, /const branches:/);
  assert.match(gallerySource, /branchPath/);
  // A central hub displays the caption for the active fruit.
  assert.match(gallerySource, /function CenterHub/);
  assert.match(gallerySource, /AnimatePresence/);
  // Hover/focus/click selects a fruit instead of relying on long scroll.
  assert.match(gallerySource, /onMouseEnter=/);
  assert.match(gallerySource, /useState/);
  // The composition stays inside a fixed aspect-ratio frame, not a
  // tall stack of alternating rows.
  assert.match(gallerySource, /aspect-\[3\/4\]/);
  assert.match(gallerySource, /aspect-\[16\/10\]/);
});
