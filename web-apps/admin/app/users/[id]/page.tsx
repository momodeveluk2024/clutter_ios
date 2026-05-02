import { api } from "@/lib/api";
import { PageHeader } from "@/components/ui/PageHeader";
import { Card } from "@/components/ui/Card";
import { Button } from "@/components/ui/Button";
import { Chip } from "@/components/ui/Chip";
import { Avatar } from "@/components/ui/Avatar";
import { KpiCard } from "@/components/ui/KpiCard";
import { NutrientPill } from "@/components/ui/NutrientPill";
import { fmtRelative } from "@/lib/utils";
import { deleteUser, revokeUserSession, saveUserProfile, suspendUser, unsuspendUser, verifyUser } from "./actions";

export const dynamic = "force-dynamic";

export default async function UserDetailPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  const user = await api.getUser(id);

  return (
    <div className="p-8">
      <PageHeader title="User profile" actions={<Button variant="ghost" size="sm" href="/users">Back to users</Button>} />

      <Card className="!p-6 mb-4">
        <div className="grid grid-cols-[auto_1fr_auto] gap-6 items-center">
          <Avatar initials={user.initials} seed={user.email} size="lg" />
          <div>
            <div className="flex items-center gap-3 mb-1">
              <h1 className="text-2xl font-bold tracking-tight">{user.displayName}</h1>
              {user.status === "verified" && <Chip variant="accent" dot>Verified</Chip>}
              {user.status === "unverified" && <Chip variant="warn" dot>Unverified</Chip>}
              {user.status === "suspended" && <Chip variant="err" dot>Suspended</Chip>}
              {user.status === "pending_deletion" && <Chip variant="err" dot>Pending deletion</Chip>}
            </div>
            <div className="flex flex-wrap gap-x-6 gap-y-1 text-[13px] text-[var(--color-text-muted)]">
              <span>{user.email}</span>
              {user.sex && user.age && <span className="capitalize">{user.sex} - {user.age} - {user.activity} activity</span>}
              <span>Joined {user.joined}</span>
              <span>{user.platform}</span>
            </div>
          </div>
          <div className="flex gap-2">
            {user.status === "unverified" && <form action={verifyUser.bind(null, id)}><Button variant="ghost" size="sm" type="submit">Verify email</Button></form>}
            {user.status === "suspended"
              ? <form action={unsuspendUser.bind(null, id)}><Button variant="ghost" size="sm" type="submit">Unsuspend</Button></form>
              : <form action={suspendUser.bind(null, id)}><Button variant="danger" size="sm" type="submit">Suspend</Button></form>}
          </div>
        </div>
      </Card>

      <Card className="!p-6 mb-4">
        <form action={saveUserProfile.bind(null, id)} className="grid grid-cols-1 md:grid-cols-6 gap-3 items-end">
          <Field label="Display name"><input name="displayName" className="input" defaultValue={user.displayName} /></Field>
          <Field label="Sex"><input name="sex" className="input" defaultValue={user.sex ?? ""} /></Field>
          <Field label="Activity"><input name="activity" className="input" defaultValue={user.activity ?? ""} /></Field>
          <Field label="Timezone"><input name="timezone" className="input" defaultValue={user.timezone ?? ""} /></Field>
          <Field label="Units"><input name="units" className="input" defaultValue={user.units ?? ""} /></Field>
          <Button variant="primary" size="sm" type="submit">Save profile</Button>
        </form>
      </Card>

      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 mb-6">
        <KpiCard label="Logs (30d)" value={user.logs30d} />
        <KpiCard label="Reminders" value={user.reminderCount ?? 0} />
        <KpiCard label="Active sessions" value={(user.sessions ?? []).filter((s) => !s.revokedAt).length} />
        <KpiCard label="Safety" value={user.status === "suspended" ? 1 : 0} helper={user.safetyStatus ?? user.status} />
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-[2fr_1fr] gap-4">
        <Card>
          <div className="flex items-center justify-between mb-4">
            <div>
              <h3 className="text-lg font-semibold tracking-tight">Recent meal logs</h3>
              <p className="text-[12px] text-[var(--color-text-muted)]">Latest database rows for this user</p>
            </div>
            <a href={`/meal-logs?user_id=${encodeURIComponent(id)}`} className="text-[12px] text-[var(--color-text-muted)] hover:text-[var(--color-text)]">All logs</a>
          </div>
          <table className="w-full text-[13px]">
            <thead className="border-b border-[var(--color-border)]">
              <tr>
                <th className="px-3 py-2.5 text-left text-[10px] font-bold uppercase text-[var(--color-text-muted)]">Date</th>
                <th className="px-3 py-2.5 text-left text-[10px] font-bold uppercase text-[var(--color-text-muted)]">Meal</th>
                <th className="px-3 py-2.5 text-left text-[10px] font-bold uppercase text-[var(--color-text-muted)]">Items</th>
                <th className="px-3 py-2.5 text-left text-[10px] font-bold uppercase text-[var(--color-text-muted)]">Top nutrients</th>
              </tr>
            </thead>
            <tbody>
              {(user.recentLogs ?? []).map((log) => (
                <tr key={log.id} className="border-b border-[var(--color-border)] last:border-0">
                  <td className="px-3 py-3">{new Date(log.loggedAt).toLocaleDateString("en-US", { month: "short", day: "numeric" })}</td>
                  <td className="px-3 py-3 capitalize">{log.meal}</td>
                  <td className="px-3 py-3">{log.items}</td>
                  <td className="px-3 py-3"><div className="flex gap-1">{log.topNutrients.map((code) => <NutrientPill key={code} code={code} size="sm" />)}</div></td>
                </tr>
              ))}
              {(user.recentLogs ?? []).length === 0 && (
                <tr><td className="px-3 py-6 text-[var(--color-text-muted)]" colSpan={4}>No logs found for this user.</td></tr>
              )}
            </tbody>
          </table>
        </Card>

        <div className="space-y-4">
          <Card>
            <h3 className="text-lg font-semibold tracking-tight mb-4">Sessions</h3>
            <div className="space-y-3.5">
              {(user.sessions ?? []).map((session) => (
                <div key={session.id} className="flex items-start gap-3">
                  <span className={`mt-1.5 w-2 h-2 rounded-full ${session.revokedAt ? "bg-[var(--color-text-muted)]" : "bg-[var(--color-accent)]"} shrink-0`} />
                  <div className="flex-1 text-[13px]">
                    <strong>{session.userAgent ?? "Unknown device"}</strong>
                    <small className="block text-[var(--color-text-muted)] text-[11px] mt-0.5">{session.ip ?? "unknown ip"} - expires {fmtRelative(session.expiresAt)}</small>
                  </div>
                  {!session.revokedAt && <form action={revokeUserSession.bind(null, id, session.id)}><Button variant="ghost" size="xs" type="submit">Revoke</Button></form>}
                </div>
              ))}
            </div>
          </Card>

          <Card className="!border-[#F0D2D2]">
            <h3 className="text-lg font-semibold tracking-tight text-[var(--color-err)]">Danger zone</h3>
            <p className="text-[12px] text-[var(--color-text-muted)] mb-4 mt-1">These actions update the database and revoke sessions where needed.</p>
            <div className="flex flex-col gap-2">
              <form action={verifyUser.bind(null, id)}><Button variant="danger" size="sm" type="submit">Force email verification</Button></form>
              <form action={suspendUser.bind(null, id)}><Button variant="danger" size="sm" type="submit">Suspend account</Button></form>
              <form action={deleteUser.bind(null, id)}><Button variant="danger" size="sm" type="submit">Delete account</Button></form>
            </div>
          </Card>
        </div>
      </div>
      <style>{`.input { width: 100%; height: 36px; padding: 0 10px; background: white; border: 1px solid var(--color-border); border-radius: 10px; font-size: 12px; }`}</style>
    </div>
  );
}

function Field({ label, children }: { label: string; children: React.ReactNode }) {
  return (
    <label className="block text-[12px] font-semibold">
      <span className="block mb-1.5">{label}</span>
      {children}
    </label>
  );
}
