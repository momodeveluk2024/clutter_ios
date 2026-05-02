import { notFound } from "next/navigation";
import { api } from "@/lib/api";
import { PageHeader } from "@/components/ui/PageHeader";
import { Button } from "@/components/ui/Button";
import { Card } from "@/components/ui/Card";
import { Chip } from "@/components/ui/Chip";
import { Avatar } from "@/components/ui/Avatar";
import { NutrientPill } from "@/components/ui/NutrientPill";
import { fmtRelative } from "@/lib/utils";

export const dynamic = "force-dynamic";

export default async function MealLogDetailPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  const logs = await api.listMealLogs();
  const log = logs.find((item) => item.id === id);

  if (!log) {
    notFound();
  }

  return (
    <div className="p-8">
      <PageHeader
        title="Meal log detail"
        sub={`${log.userEmail} - ${new Date(log.loggedAt).toLocaleString("en-US", { month: "short", day: "numeric", hour: "2-digit", minute: "2-digit" })}`}
        actions={<Button variant="ghost" size="sm" href="/meal-logs">Back to logs</Button>}
      />

      <div className="grid grid-cols-1 lg:grid-cols-[1.3fr_0.7fr] gap-4">
        <Card>
          <div className="flex items-start justify-between gap-4 mb-5">
            <div className="flex items-center gap-3">
              <Avatar initials={log.userInitials} seed={log.userEmail} size="md" />
              <div>
                <a href={`/users/${log.userId}`} className="font-semibold hover:text-[var(--color-accent-deep)]">{log.userEmail}</a>
                <p className="text-[12px] text-[var(--color-text-muted)]">{fmtRelative(log.loggedAt)}</p>
              </div>
            </div>
            {log.flagged ? <Chip variant="warn" dot>Needs review</Chip> : <Chip variant="accent" dot>Logged</Chip>}
          </div>

          <dl className="grid grid-cols-1 sm:grid-cols-2 gap-4 text-[13px]">
            <div>
              <dt className="eyebrow mb-1">Meal</dt>
              <dd className="capitalize">{log.meal}</dd>
            </div>
            <div>
              <dt className="eyebrow mb-1">Logged at</dt>
              <dd>{new Date(log.loggedAt).toLocaleString("en-US")}</dd>
            </div>
            <div className="sm:col-span-2">
              <dt className="eyebrow mb-1">Items</dt>
              <dd className={log.flagged ? "text-[var(--color-warn)]" : ""}>{log.flagged ? "No items attached to this log." : log.items}</dd>
            </div>
          </dl>
        </Card>

        <Card>
          <h3 className="text-lg font-semibold tracking-tight mb-3">Top nutrients</h3>
          <div className="flex flex-wrap gap-2">
            {log.topNutrients.map((code) => <NutrientPill key={code} code={code} size="md" />)}
            {log.topNutrients.length === 0 && <span className="text-[13px] text-[var(--color-text-muted)]">No nutrient totals for this log.</span>}
          </div>
        </Card>
      </div>
    </div>
  );
}
