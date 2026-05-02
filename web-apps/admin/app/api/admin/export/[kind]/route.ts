import {
  exportFoodsCsv,
  exportMealLogsCsv,
  exportNutrientsCsv,
  exportReminderTemplatesCsv,
  exportUsersCsv,
} from "@/lib/api";

export const dynamic = "force-dynamic";

export async function GET(_request: Request, { params }: { params: Promise<{ kind: string }> }) {
  const { kind } = await params;
  const exporters: Record<string, () => Promise<string>> = {
    foods: exportFoodsCsv,
    users: exportUsersCsv,
    "meal-logs": exportMealLogsCsv,
    nutrients: exportNutrientsCsv,
    "reminder-templates": exportReminderTemplatesCsv,
  };
  const makeCsv = exporters[kind];
  if (!makeCsv) {
    return Response.json({ error: "unknown export" }, { status: 404 });
  }
  const csv = await makeCsv();
  return new Response(csv, {
    headers: {
      "Content-Type": "text/csv; charset=utf-8",
      "Content-Disposition": `attachment; filename="${kind}.csv"`,
    },
  });
}
