// Mirror of web/shared/tokens.ts (each Next.js app keeps its copy because
// Turbopack won't resolve imports outside the app root).

export type NutrientCode =
  | "A" | "C" | "D" | "E" | "K"
  | "B6" | "B9" | "B12"
  | "B1" | "B2" | "B3" | "B5" | "B7"
  | "Fe" | "Zn" | "Mg" | "Ca" | "Kp" | "Mn" | "Na" | "P" | "S" | "Se"
  | "Protein" | "Carbs" | "Fat" | "Fiber";

export const nutrientHues: Partial<Record<NutrientCode, { fill: string; bg: string }>> = {
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
  Protein: { fill: "#5E6A63", bg: "#EEF1EA" },
  Carbs: { fill: "#8A6D3B", bg: "#F4EAD7" },
  Fat: { fill: "#8A4D68", bg: "#F2E1EA" },
  Fiber: { fill: "#617A2E", bg: "#E8EFD7" },
};
