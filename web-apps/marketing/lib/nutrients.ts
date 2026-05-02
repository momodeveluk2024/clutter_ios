import { nutrientHues, type NutrientCode } from "./tokens";

export { nutrientHues, type NutrientCode };

export type Nutrient = {
  code: NutrientCode;
  name: string;
  unit: string;
  group: "vitamin" | "mineral" | "macro";
  oneLiner: string;
};

export const nutrients: Nutrient[] = [
  { code: "A",   name: "Vitamin A",  unit: "mcg RAE", group: "vitamin", oneLiner: "Vision, immune system, skin." },
  { code: "C",   name: "Vitamin C",  unit: "mg",      group: "vitamin", oneLiner: "Collagen, iron uptake, antioxidant." },
  { code: "D",   name: "Vitamin D",  unit: "mcg",     group: "vitamin", oneLiner: "Bones, mood, immunity." },
  { code: "E",   name: "Vitamin E",  unit: "mg",      group: "vitamin", oneLiner: "Cell membranes, antioxidant." },
  { code: "K",   name: "Vitamin K",  unit: "mcg",     group: "vitamin", oneLiner: "Blood clotting, bone density." },
  { code: "B6",  name: "Vitamin B6", unit: "mg",      group: "vitamin", oneLiner: "Brain, nervous system." },
  { code: "B9",  name: "Folate",     unit: "mcg DFE", group: "vitamin", oneLiner: "DNA synthesis, red blood cells." },
  { code: "B12", name: "Vitamin B12",unit: "mcg",     group: "vitamin", oneLiner: "Energy, nerves. Often missing on plant diets." },
  { code: "Fe",  name: "Iron",       unit: "mg",      group: "mineral", oneLiner: "Oxygen transport. Common deficiency." },
  { code: "Zn",  name: "Zinc",       unit: "mg",      group: "mineral", oneLiner: "Immune function, wound healing." },
  { code: "Mg",  name: "Magnesium",  unit: "mg",      group: "mineral", oneLiner: "Muscles, sleep, 300+ enzymes." },
  { code: "Ca",  name: "Calcium",    unit: "mg",      group: "mineral", oneLiner: "Bones, teeth, muscle contraction." },
];

export function nutrientByCode(code: NutrientCode): Nutrient {
  return nutrients.find((n) => n.code === code)!;
}
