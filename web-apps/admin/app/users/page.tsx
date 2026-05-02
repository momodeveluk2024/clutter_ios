import { api } from "@/lib/api";
import { PageHeader } from "@/components/ui/PageHeader";
import { Button } from "@/components/ui/Button";
import { Chip } from "@/components/ui/Chip";
import { Avatar } from "@/components/ui/Avatar";
import { KpiCard } from "@/components/ui/KpiCard";
import { Table, THead, TH, TBody, TRow, TD } from "@/components/ui/Table";
import { fmtRelative } from "@/lib/utils";
import { Download } from "lucide-react";

export const dynamic = "force-dynamic";

export default async function UsersPage() {
  const users = await api.listUsers();
  const sevenDaysAgo = Date.now() - 7 * 24 * 60 * 60 * 1000;
  const active7d = users.filter((u) => u.lastActive && new Date(u.lastActive).getTime() >= sevenDaysAgo).length;
  const unverified = users.filter((u) => u.status === "unverified").length;
  const pendingDeletion = users.filter((u) => u.status === "pending_deletion").length;

  return (
    <div className="p-8">
      <PageHeader
        title="Users"
        sub={`${users.length} users loaded - ${unverified} unverified - ${pendingDeletion} pending deletion`}
        actions={<Button variant="ghost" size="sm" href="/api/admin/export/users"><Download size={12} /> Export</Button>}
      />

      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 mb-6">
        <KpiCard label="Total users" value={users.length} helper="loaded from backend" />
        <KpiCard label="Active 7d" value={active7d} helper="recent session activity" />
        <KpiCard label="Unverified" value={unverified} emphasisColor="var(--color-warn)" helper="email not verified" />
        <KpiCard label="Pending deletion" value={pendingDeletion} emphasisColor="var(--color-err)" helper="GDPR window" />
      </div>

      <div className="rounded-t-[18px] border border-b-0 border-[var(--color-border)] bg-[var(--color-surface)] p-3 flex gap-2 items-center">
        <input
          placeholder="Filter by email, name..."
          className="h-9 px-3 bg-white border border-[var(--color-border)] rounded-[10px] text-[13px] flex-1 max-w-xs focus:outline-none focus:border-[var(--color-accent)] focus:ring-2 focus:ring-[var(--color-accent-soft)]"
        />
        <select className="h-9 px-3 bg-white border border-[var(--color-border)] rounded-[10px] text-[13px]">
          <option>All status</option><option>Verified</option><option>Unverified</option><option>Pending deletion</option>
        </select>
        <select className="h-9 px-3 bg-white border border-[var(--color-border)] rounded-[10px] text-[13px]">
          <option>All cohorts</option><option>iOS</option><option>Android</option>
        </select>
      </div>

      <Table className="rounded-t-none border-t-0">
        <THead>
          <TH className="w-8"><input type="checkbox" /></TH>
          <TH>User</TH>
          <TH>Email</TH>
          <TH>Profile</TH>
          <TH>Logs (30d)</TH>
          <TH>Last active</TH>
          <TH>Status</TH>
          <TH><span className="sr-only">Actions</span></TH>
        </THead>
        <TBody>
          {users.map((u, i) => (
            <TRow key={u.id} index={i}>
              <TD><input type="checkbox" /></TD>
              <TD>
                <div className="flex items-center gap-2.5">
                  <Avatar initials={u.initials} seed={u.email} size="sm" />
                  <a href={`/users/${u.id}`} className="font-semibold text-[var(--color-text)] hover:text-[var(--color-accent-deep)]">
                    {u.displayName}
                  </a>
                </div>
              </TD>
              <TD className="text-[var(--color-text-muted)]">{u.email}</TD>
              <TD className="text-[var(--color-text-muted)] text-[12px] capitalize">
                {u.sex && u.age ? `${u.sex} - ${u.age} - ${u.activity}` : "-"}
              </TD>
              <TD className="tabular font-semibold">{u.logs30d}</TD>
              <TD className="text-[var(--color-text-muted)] text-[12px]">{fmtRelative(u.lastActive)}</TD>
              <TD>
                {u.status === "verified" && <Chip variant="accent" dot>Verified</Chip>}
                {u.status === "unverified" && <Chip variant="warn" dot>Unverified</Chip>}
                {u.status === "pending_deletion" && <Chip variant="err" dot>Pending deletion</Chip>}
              </TD>
              <TD>
                <a href={`/users/${u.id}`} className="text-[var(--color-text-muted)] text-[12px] hover:text-[var(--color-text)]">Open</a>
              </TD>
            </TRow>
          ))}
        </TBody>
      </Table>
    </div>
  );
}
