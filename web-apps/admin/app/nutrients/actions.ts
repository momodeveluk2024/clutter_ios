"use server";

import { revalidatePath } from "next/cache";
import { mutateJson, exportNutrientsCsv } from "@/lib/api";

function nutrientBody(formData: FormData) {
  return {
    code: String(formData.get("code") ?? "").trim(),
    name: String(formData.get("name") ?? "").trim(),
    unit: String(formData.get("unit") ?? "").trim(),
    group: String(formData.get("group") ?? "vitamin").trim(),
    driAdult: Number(formData.get("driAdult") ?? 0),
  };
}

export async function createNutrient(formData: FormData) {
  await mutateJson("/admin/nutrients", nutrientBody(formData), "POST");
  revalidatePath("/nutrients");
}

export async function updateNutrient(code: string, formData: FormData) {
  await mutateJson(`/admin/nutrients/${encodeURIComponent(code)}`, nutrientBody(formData), "PATCH");
  revalidatePath("/nutrients");
}

export { exportNutrientsCsv };
