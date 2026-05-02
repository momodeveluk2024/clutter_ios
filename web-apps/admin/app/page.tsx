import { api } from "@/lib/api";
import { PageHeader } from "@/components/ui/PageHeader";
import { KpiCard } from "@/components/ui/KpiCard";
import { Card } from "@/components/ui/Card";
import { Button } from "@/components/ui/Button";
import { LogsChart } from "@/components/ui/LogsChart";
import { Chip } from "@/components/ui/Chip";
import { NutrientPill } from "@/components/ui/NutrientPill";
import { Download } from "lucide-react";

export const dynamic = "force-dynamic";

export default async function OverviewPage({ searchParams }: { searchParams: Promise<{ range?: string }> }) {
  const { range = "week" } = await searchParams;
  const [overview, logs] = await Promise.all([api.overview(range), api.listMealLogs()]);
  const recentLogs = logs.slice(0, 6);

  return (
    <div className="p-8">
      <PageHeader
        title="Admin overview"
        sub="Live activity from the Go backend."
        actions={
          <>
            <Button variant={range === "week" ? "primary" : "ghost"} size="sm" href="/?range=week">Week</Button>
            <Button variant={range === "month" ? "primary" : "ghost"} size="sm" href="/?range=month">Month</Button>
            <Button variant={range === "year" ? "primary" : "ghost"} size="sm" href="/?range=year">Year</Button>
            <Button variant="ghost" size="sm" href="/api/admin/export/meal-logs"><Download size={12} /> Export</Button>
          </>
        }
      />

      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 mb-6">
        <KpiCard
          label="Active users (7d)"
          value={overview.kpis.activeUsers7d.value}
          helper="users with recent sessions"
        />
        <KpiCard
          label="Meals logged today"
          value={overview.kpis.mealsLoggedToday.value}
          helper="from today's logs"
        />
        <KpiCard
          label="Foods in catalog"
          value={overview.kpis.foodsInCatalog.value}
          helper={`+${overview.kpis.foodsInCatalog.addedThisWeek} this week`}
        />
        <KpiCard
          label="Pending verification"
          value={overview.kpis.pendingVerification.value}
          emphasisColor="var(--color-warn)"
          helper={`${overview.kpis.pendingVerification.over7days ?? 0} over 7 days old`}
        />
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-[2fr_1fr] gap-4">
        <Card>
          <div className="flex items-start justify-between mb-4">
            <div>
              <h3 className="text-lg font-semibold tracking-tight">Meal log volume</h3>
              <p className="text-[12px] text-[var(--color-text-muted)]">
                {range === "year" ? "Last 12 months" : range === "month" ? "Last 30 days" : "Last 7 days"} · all users
              </p>
            </div>
            <div className="flex gap-1.5">
              <Chip variant="accent" dot>Logs</Chip>
            </div>
          </div>
          <LogsChart data={overview.logsByDay} />
        </Card>

        <Card>
          <h3 className="text-lg font-semibold tracking-tight mb-4">Recent activity</h3>
          <div className="space-y-3.5">
            {recentLogs.map((log) => (
              <ActivityItem
                key={log.id}
                dot={log.flagged ? "warn" : "ok"}
                text={<><b>{log.userEmail}</b> logged <a href={`/meal-logs/${log.id}`} className="text-[var(--color-accent-deep)] underline-offset-2 hover:underline">{log.meal}</a></>}
                time={new Date(log.loggedAt).toLocaleString("en-US", { month: "short", day: "numeric", hour: "2-digit", minute: "2-digit" })}
              />
            ))}
            {recentLogs.length === 0 && (
              <ActivityItem dot="muted" text="No recent meal logs found" time="Backend returned an empty feed" />
            )}
          </div>
          <a href="/meal-logs" className="text-[12px] text-[var(--color-text-muted)] hover:text-[var(--color-text)] mt-4 inline-block">View all -&gt;</a>
        </Card>
      </div>

      <Card className="mt-4">
        <div className="flex items-start justify-between mb-5">
          <div>
            <h3 className="text-lg font-semibold tracking-tight">Most-tracked nutrients</h3>
            <p className="text-[12px] text-[var(--color-text-muted)]">By number of logs - last 30 days</p>
          </div>
          <a href="/nutrients" className="text-[12px] text-[var(--color-text-muted)] hover:text-[var(--color-text)]">Manage nutrients -&gt;</a>
        </div>
        <div className="flex gap-x-6 gap-y-3 flex-wrap">
          {overview.topNutrients.map((n) => (
            <div key={n.code} className="flex items-center gap-2.5">
              <NutrientPill code={n.code} size="md" />
              <span className="text-[13px] tabular">{n.logs.toLocaleString()} logs</span>
            </div>
          ))}
        </div>
      </Card>
    </div>
  );
}

function ActivityItem({ dot, text, time }: { dot: "ok" | "warn" | "muted"; text: React.ReactNode; time: string }) {
  const color = dot === "ok" ? "bg-[var(--color-accent)]" : dot === "warn" ? "bg-[var(--color-warn)]" : "bg-[var(--color-text-muted)]";
  return (
    <div className="flex gap-3 items-start">
      <span className={`mt-1.5 w-2 h-2 rounded-full ${color} shrink-0`} />
      <div className="flex-1 text-[13px] leading-relaxed">
        {text}
        <small className="block text-[var(--color-text-muted)] text-[11px] mt-0.5">{time}</small>
      </div>
    </div>
  );
}
