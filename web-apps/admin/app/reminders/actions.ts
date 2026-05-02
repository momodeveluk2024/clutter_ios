"use server";

import { revalidatePath } from "next/cache";
import { mutateJson, exportReminderTemplatesCsv } from "@/lib/api";

function body(formData: FormData) {
  return {
    title: String(formData.get("title") ?? "").trim(),
    body: String(formData.get("body") ?? "").trim(),
    trigger: String(formData.get("trigger") ?? "").trim(),
    audience: String(formData.get("audience") ?? "all").trim(),
    active: formData.get("active") === "on",
  };
}

export async function createReminderTemplate(formData: FormData) {
  await mutateJson("/admin/reminder-templates", body(formData), "POST");
  revalidatePath("/reminders");
}

export async function updateReminderTemplate(id: string, formData: FormData) {
  await mutateJson(`/admin/reminder-templates/${id}`, body(formData), "PATCH");
  revalidatePath("/reminders");
}

export { exportReminderTemplatesCsv };
