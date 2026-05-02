"use server";

import { redirect } from "next/navigation";
import { revalidatePath } from "next/cache";
import { deleteResource, mutateJson, exportUsersCsv } from "@/lib/api";

export async function saveUserProfile(userId: string, formData: FormData) {
  await mutateJson(`/admin/users/${userId}`, {
    displayName: String(formData.get("displayName") ?? "").trim(),
    sex: String(formData.get("sex") ?? "").trim() || undefined,
    activity: String(formData.get("activity") ?? "").trim() || undefined,
    timezone: String(formData.get("timezone") ?? "").trim() || undefined,
    units: String(formData.get("units") ?? "").trim() || undefined,
  }, "PATCH");
  revalidatePath("/users");
  revalidatePath(`/users/${userId}`);
}

export async function verifyUser(userId: string) {
  await mutateJson(`/admin/users/${userId}/verify`, {}, "POST");
  revalidatePath("/users");
  revalidatePath(`/users/${userId}`);
}

export async function suspendUser(userId: string) {
  await mutateJson(`/admin/users/${userId}/suspend`, {}, "POST");
  revalidatePath("/users");
  revalidatePath(`/users/${userId}`);
}

export async function unsuspendUser(userId: string) {
  await mutateJson(`/admin/users/${userId}/unsuspend`, {}, "POST");
  revalidatePath("/users");
  revalidatePath(`/users/${userId}`);
}

export async function deleteUser(userId: string) {
  await deleteResource(`/admin/users/${userId}`);
  revalidatePath("/users");
  redirect("/users");
}

export async function revokeUserSession(userId: string, sessionId: string) {
  await deleteResource(`/admin/users/${userId}/sessions/${sessionId}`);
  revalidatePath(`/users/${userId}`);
}

export { exportUsersCsv };
