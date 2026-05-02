import { api } from "@/lib/api";
import { PageHeader } from "@/components/ui/PageHeader";
import { Button } from "@/components/ui/Button";
import { Chip } from "@/components/ui/Chip";
import { Avatar } from "@/components/ui/Avatar";
import { KpiCard } from "@/components/ui/KpiCard";
import { NutrientPill } from "@/components/ui/NutrientPill";
import { Table, THead, TH, TBody, TRow, TD } from "@/components/ui/Table";
import { fmtRelative } from "@/lib/utils";
import { Download } from "lucide-react";

export const dynamic = "force-dynamic";

export default async function MealLogsPage({ searchParams }: { searchParams: Promise<{ range?: string }> }) {
  const { range = "week" } = await searchParams;
  const now = new Date();
  const fromDate = new Date(now);
  fromDate.setDate(now.getDate() - (range === "year" ? 365 : range === "month" ? 30 : 7));
  const logs = await api.listMealLogs({ from: fromDate.toISOString().slice(0, 10), to: now.toISOString().slice(0, 10) });
  const today = new Date().toISOString().slice(0, 10);
  const logsToday = logs.filter((log) => log.loggedAt.slice(0, 10) === today).length;
  const representedUsers = new Set(logs.map((log) => log.userId)).size;
  const avgPerUser = representedUsers === 0 ? 0 : logs.length / representedUsers;
  const flaggedLogs = logs.filter((log) => log.flagged).length;

  return (
    <div className="p-8">
      <PageHeader
        title="Meal logs"
        sub="Read-only feed across all users - for moderation and abuse review"
        actions={<Button variant="ghost" size="sm" href="/api/admin/export/meal-logs"><Download size={12} /> Export</Button>}
      />

      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 mb-6">
        <KpiCard label="Logs today" value={logsToday} helper="from loaded admin feed" />
        <KpiCard label="Logs in table" value={logs.length} helper="latest backend rows" />
        <KpiCard label="Avg / user" value={avgPerUser} decimals={1} helper={`${representedUsers} users represented`} />
        <KpiCard label="Flagged" value={flaggedLogs} emphasisColor="var(--color-warn)" helper="empty logs require review" />
      </div>

      <div className="rounded-t-[18px] border border-b-0 border-[var(--color-border)] bg-[var(--color-surface)] p-3 flex gap-2 items-center flex-wrap">
        <input
          placeholder="Filter by user email or food name..."
          className="h-9 px-3 bg-white border border-[var(--color-border)] rounded-[10px] text-[13px] flex-1 min-w-[240px] max-w-sm focus:outline-none focus:border-[var(--color-accent)] focus:ring-2 focus:ring-[var(--color-accent-soft)]"
        />
        <select className="h-9 px-3 bg-white border border-[var(--color-border)] rounded-[10px] text-[13px]">
          <option>All meals</option><option>Breakfast</option><option>Lunch</option><option>Snack</option><option>Dinner</option>
        </select>
        <Button variant={range === "week" ? "primary" : "ghost"} size="sm" href="/meal-logs?range=week">Week</Button>
        <Button variant={range === "month" ? "primary" : "ghost"} size="sm" href="/meal-logs?range=month">Month</Button>
        <Button variant={range === "year" ? "primary" : "ghost"} size="sm" href="/meal-logs?range=year">Year</Button>
      </div>

      <Table className="rounded-t-none border-t-0">
        <THead>
          <TH>Logged</TH>
          <TH>User</TH>
          <TH>Meal</TH>
          <TH>Items</TH>
          <TH>Top nutrients</TH>
          <TH><span className="sr-only">Actions</span></TH>
        </THead>
        <TBody>
          {logs.map((log, i) => (
            <TRow key={log.id} index={i}>
              <TD>
                {fmtRelative(log.loggedAt)}
                <div className="text-[11px] text-[var(--color-text-muted)] mt-0.5">
                  {new Date(log.loggedAt).toLocaleString("en-US", { month: "short", day: "numeric", hour: "2-digit", minute: "2-digit" })}
                </div>
              </TD>
              <TD>
                <div className="flex items-center gap-2">
                  <Avatar initials={log.userInitials} seed={log.userEmail} size="xs" />
                  <a href={`/users/${log.userId}`} className="text-[var(--color-text-muted)] hover:text-[var(--color-text)]">{log.userEmail}</a>
                </div>
              </TD>
              <TD><Chip variant="default" className="capitalize">{log.meal}</Chip></TD>
              <TD>
                {log.flagged ? (
                  <>
                    <span className="text-[var(--color-text-muted)]">[no items]</span>
                    <div className="text-[11px] text-[var(--color-warn)] mt-0.5">empty log - flagged</div>
                  </>
                ) : log.items}
              </TD>
              <TD>
                <div className="flex gap-1">
                  {log.topNutrients.map((c) => <NutrientPill key={c} code={c} size="sm" />)}
                  {log.topNutrients.length === 0 && <span className="text-[var(--color-text-muted)]">-</span>}
                </div>
              </TD>
              <TD>
                {log.flagged
                  ? <a href={`/meal-logs/${log.id}`} className="text-[var(--color-warn)] text-[12px]">Review</a>
                  : <a href={`/meal-logs/${log.id}`} className="text-[var(--color-text-muted)] text-[12px] hover:text-[var(--color-text)]">View</a>}
              </TD>
            </TRow>
          ))}
        </TBody>
      </Table>
    </div>
  );
}
