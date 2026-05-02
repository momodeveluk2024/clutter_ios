// NV — single source of design truth for both Next.js apps (marketing + future admin).
// Mirrors web/DESIGN.md and myapplication/lib/theme.dart.

export const colors = {
  bg: "#F6F7F3",
  surface: "#FFFFFF",
  surfaceMuted: "#EEF1EA",
  border: "#E5E8DF",
  text: "#131A16",
  textMuted: "#5E6A63",
  accent: "#2F7D4A",
  accentSoft: "#E6F1E9",
  accentDeep: "#1E5A34",
  warn: "#C57420",
  err: "#B23A3A",
  bgDark: "#0F1512",
  surfaceDark: "#18201C",
  surfaceMutedDark: "#1F2823",
  borderDark: "#2A332D",
  textDark: "#F1F3EE",
  textMutedDark: "#9AA89F",
} as const;

export type NutrientCode =
  | "A" | "C" | "D" | "E" | "K"
  | "B6" | "B9" | "B12"
  | "Fe" | "Zn" | "Mg" | "Ca";

export const nutrientHues: Record<NutrientCode, { fill: string; bg: string }> = {
  A:   { fill: "#E88A3D", bg: "#FBEADB" },
  C:   { fill: "#2F7D4A", bg: "#E6F1E9" },
  D:   { fill: "#C79B1A", bg: "#F7EFD3" },
  E:   { fill: "#7A5CC0", bg: "#EBE6F6" },
  K:   { fill: "#3A6B88", bg: "#E1ECF2" },
  B6:  { fill: "#B23A5C", bg: "#F4E0E6" },
  B9:  { fill: "#6B8E3A", bg: "#E9EFDA" },
  B12: { fill: "#1E7A82", bg: "#DCECEE" },
  Fe:  { fill: "#8A4B3D", bg: "#F1DFDB" },
  Zn:  { fill: "#4A5B70", bg: "#DEE3EA" },
  Mg:  { fill: "#2B8079", bg: "#DAEDEA" },
  Ca:  { fill: "#A07DBB", bg: "#ECE3F2" },
};
