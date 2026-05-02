"use server";

import { redirect } from "next/navigation";
import { revalidatePath } from "next/cache";
import { backendFetch, mutateFormData, mutateJson, exportFoodsCsv } from "@/lib/api";

function optionalString(formData: FormData, name: string) {
  const value = String(formData.get(name) ?? "").trim();
  return value === "" ? undefined : value;
}

function parseNutrients(formData: FormData) {
  const codes = formData.getAll("nutrientCode").map((v) => String(v).trim()).filter(Boolean);
  const amounts = formData.getAll("nutrientAmount").map((v) => Number(v));
  return codes.map((code, index) => ({
    code,
    amount_per_100g: Number.isFinite(amounts[index]) && amounts[index] >= 0 ? amounts[index] : 0,
  }));
}

export async function saveFood(foodId: string, formData: FormData) {
  const serving = Number(formData.get("servingSizeG"));
  const body = {
    name: optionalString(formData, "name"),
    brand: optionalString(formData, "brand"),
    category: optionalString(formData, "category"),
    servingSizeG: Number.isFinite(serving) && serving > 0 ? serving : undefined,
    imageUrl: optionalString(formData, "imageUrl"),
    barcode: optionalString(formData, "barcode"),
    source: optionalString(formData, "source"),
    verified: formData.get("verified") === "on",
    nutrients: parseNutrients(formData),
  };

  await mutateJson(`/admin/foods/${foodId}`, body, "PATCH");
  revalidatePath("/foods");
  revalidatePath(`/foods/${foodId}`);
}

export async function createFood(formData: FormData) {
  const serving = Number(formData.get("servingSizeG"));
  const food = await mutateJson<{ id: string }>("/admin/foods", {
    name: optionalString(formData, "name") ?? "",
    brand: optionalString(formData, "brand"),
    category: optionalString(formData, "category") ?? "general",
    servingSizeG: Number.isFinite(serving) && serving > 0 ? serving : 100,
    imageUrl: optionalString(formData, "imageUrl"),
    barcode: optionalString(formData, "barcode"),
    source: optionalString(formData, "source") ?? "manual",
    verified: formData.get("verified") === "on",
    nutrients: parseNutrients(formData),
  });
  revalidatePath("/foods");
  redirect(`/foods/${food.id}`);
}

export async function uploadFoodImage(foodId: string, formData: FormData) {
  await mutateFormData(`/admin/foods/${foodId}/image`, formData);
  revalidatePath("/foods");
  revalidatePath(`/foods/${foodId}`);
}

export async function deleteFood(foodId: string) {
  const response = await backendFetch(`/admin/foods/${foodId}`, { method: "DELETE" });
  if (!response.ok) {
    throw new Error("Could not delete food");
  }
  revalidatePath("/foods");
  redirect("/foods");
}

export { exportFoodsCsv };
