import { PageHeader } from "@/components/ui/PageHeader";
import { Card } from "@/components/ui/Card";
import { Button } from "@/components/ui/Button";
import { Chip } from "@/components/ui/Chip";
import { Avatar } from "@/components/ui/Avatar";
import { Plus } from "lucide-react";

export default function SettingsPage() {
  return (
    <div className="p-8">
      <PageHeader title="Settings" sub="Admin profile, team, API keys and audit history" />

      <div className="grid grid-cols-1 md:grid-cols-[220px_1fr] gap-8">
        {/* Settings sub-nav */}
        <nav className="flex md:flex-col gap-1">
          <SettingsLink href="#profile" active>Profile</SettingsLink>
          <SettingsLink href="#team">Team & roles</SettingsLink>
          <SettingsLink href="#api">API keys</SettingsLink>
          <SettingsLink href="#integrations">Integrations</SettingsLink>
          <SettingsLink href="#audit">Audit log</SettingsLink>
          <SettingsLink href="#danger" danger>Danger zone</SettingsLink>
        </nav>

        <div className="space-y-4">
          <Card id="profile">
            <h3 className="text-lg font-semibold tracking-tight">Profile</h3>
            <p className="text-[12px] text-[var(--color-text-muted)] mt-1 mb-5">Your admin account.</p>

            <div className="flex items-center gap-4 mb-6">
              <Avatar initials="JM" size="lg" />
              <div>
                <Button variant="ghost" size="xs">Upload photo</Button>
                <p className="text-[11px] text-[var(--color-text-muted)] mt-1.5">PNG or JPG, max 2 MB</p>
              </div>
            </div>

            <div className="grid grid-cols-2 gap-4 mb-4">
              <Field label="Full name"><input className="input" defaultValue="Jane Miller" /></Field>
              <Field label="Email"><input className="input" defaultValue="jane@nv.app" /></Field>
            </div>
            <div className="grid grid-cols-2 gap-4 mb-6">
              <Field label="Role">
                <select className="input"><option>Owner</option><option>Editor</option><option>Viewer</option></select>
              </Field>
              <Field label="Timezone">
                <select className="input"><option>Europe/Lisbon (UTC+0)</option><option>UTC</option></select>
              </Field>
            </div>

            <div className="flex justify-end gap-2">
              <Button variant="ghost" size="sm">Cancel</Button>
              <Button variant="primary" size="sm">Save</Button>
            </div>
          </Card>

          <Card id="team">
            <div className="flex items-center justify-between mb-4">
              <div>
                <h3 className="text-lg font-semibold tracking-tight">Team & roles</h3>
                <p className="text-[12px] text-[var(--color-text-muted)] mt-1">3 admins with access</p>
              </div>
              <Button variant="primary" size="sm"><Plus size={12} /> Invite</Button>
            </div>
            <table className="w-full text-[13px]">
              <thead className="border-b border-[var(--color-border)]">
                <tr>
                  <th className="px-3 py-2.5 text-left text-[10px] font-bold tracking-[0.08em] uppercase text-[var(--color-text-muted)]">Member</th>
                  <th className="px-3 py-2.5 text-left text-[10px] font-bold tracking-[0.08em] uppercase text-[var(--color-text-muted)]">Email</th>
                  <th className="px-3 py-2.5 text-left text-[10px] font-bold tracking-[0.08em] uppercase text-[var(--color-text-muted)]">Role</th>
                  <th className="px-3 py-2.5 text-left text-[10px] font-bold tracking-[0.08em] uppercase text-[var(--color-text-muted)]">Last active</th>
                  <th><span className="sr-only">Actions</span></th>
                </tr>
              </thead>
              <tbody>
                <Member name="Jane Miller"  email="jane@nv.app"  role="Owner"  active="Now"        you  />
                <Member name="Marco Klein"  email="marco@nv.app" role="Editor" active="14 min ago" />
                <Member name="Priya Ravi"   email="priya@nv.app" role="Viewer" active="Yesterday"  />
              </tbody>
            </table>
          </Card>

          <Card id="api">
            <div className="flex items-center justify-between mb-4">
              <div>
                <h3 className="text-lg font-semibold tracking-tight">API keys</h3>
                <p className="text-[12px] text-[var(--color-text-muted)] mt-1">For server-to-server calls. Treat like passwords.</p>
              </div>
              <Button variant="primary" size="sm"><Plus size={12} /> Generate key</Button>
            </div>
            <div className="space-y-2">
              <ApiKeyRow name="Production · main"  hash="nv_live_••••••••••••••a1f2" meta="created Mar 12 · last used 2 min ago" status="active" />
              <ApiKeyRow name="USDA importer"     hash="nv_live_••••••••••••••c4e7" meta="created Feb 02 · last used Apr 22"   status="active" />
              <ApiKeyRow name="Legacy migrator"   hash="nv_live_••••••••••••••b002" meta="created Jan 04 · unused for 60 days" status="stale" />
            </div>
          </Card>

          <Card id="integrations">
            <h3 className="text-lg font-semibold tracking-tight">Integrations</h3>
            <p className="text-[12px] text-[var(--color-text-muted)] mt-1 mb-4">External services Nutrimate connects to.</p>
            <div className="space-y-2">
              <Integration name="USDA FoodData Central" desc="Source of seed nutrient data"   connected />
              <Integration name="Firebase Cloud Messaging" desc="Android push notifications"   connected />
              <Integration name="Apple Push Notification service" desc="iOS push notifications" connected />
              <Integration name="Postmark" desc="Transactional email"                          connected />
              <Integration name="Sentry" desc="Error monitoring"                                connected={false} />
            </div>
          </Card>

          <Card id="audit">
            <h3 className="text-lg font-semibold tracking-tight">Audit log</h3>
            <p className="text-[12px] text-[var(--color-text-muted)] mt-1 mb-4">Last 30 days of admin actions.</p>
            <div className="space-y-3">
              <AuditItem text={<><b>Jane Miller</b> verified food <code className="text-[12px] bg-[var(--color-surface-muted)] px-1.5 py-0.5 rounded">018f…0049</code> &ldquo;Quinoa, cooked&rdquo;</>} time="3 min ago · 78.21.4.10" />
              <AuditItem text={<><b>Marco Klein</b> created food &ldquo;Tempeh, organic&rdquo;</>} time="1 h ago · 88.12.0.54" />
              <AuditItem text={<><b>Jane Miller</b> updated DRI for Vitamin D</>} time="Yesterday" warn />
              <AuditItem text={<><b>Priya Ravi</b> exported users CSV (4,182 rows)</>} time="2 days ago" />
              <AuditItem text={<><b>Jane Miller</b> revoked API key <code className="text-[12px] bg-[var(--color-surface-muted)] px-1.5 py-0.5 rounded">nv_live_…b002</code></>} time="3 days ago" warn />
            </div>
          </Card>

          <Card id="danger" className="!border-[#F0D2D2]">
            <h3 className="text-lg font-semibold tracking-tight text-[var(--color-err)]">Danger zone</h3>
            <p className="text-[12px] text-[var(--color-text-muted)] mt-1 mb-4">Workspace-level actions. All require email confirmation.</p>
            <div className="flex flex-col gap-2 max-w-xs">
              <Button variant="danger" size="sm">Rotate all API keys</Button>
              <Button variant="danger" size="sm">Force log out all admins</Button>
              <Button variant="danger" size="sm">Delete workspace</Button>
            </div>
          </Card>
        </div>
      </div>

      <style>{`
        .input {
          width: 100%; height: 38px; padding: 0 12px;
          background: white; border: 1px solid var(--color-border);
          border-radius: 10px; font-size: 13px;
          transition: border-color 0.15s, box-shadow 0.15s;
        }
        .input:focus {
          outline: none; border-color: var(--color-accent);
          box-shadow: 0 0 0 3px var(--color-accent-soft);
        }
      `}</style>
    </div>
  );
}

function SettingsLink({ children, href, active, danger }: { children: React.ReactNode; href: string; active?: boolean; danger?: boolean }) {
  const cls = danger
    ? "text-[var(--color-err)]"
    : active
      ? "bg-[var(--color-accent-soft)] text-[var(--color-accent-deep)] font-semibold"
      : "text-[var(--color-text-muted)] hover:bg-[var(--color-surface-muted)] hover:text-[var(--color-text)]";
  return <a href={href} className={`block px-3 py-2 rounded-lg text-[13px] transition-colors ${cls}`}>{children}</a>;
}

function Field({ label, children }: { label: string; children: React.ReactNode }) {
  return <div><label className="block text-[12px] font-semibold mb-1.5">{label}</label>{children}</div>;
}

function Member({ name, email, role, active, you }: { name: string; email: string; role: string; active: string; you?: boolean }) {
  const initials = name.split(" ").map(s => s[0]).join("").slice(0, 2);
  return (
    <tr className="border-b border-[var(--color-border)] last:border-0">
      <td className="px-3 py-3">
        <div className="flex items-center gap-2.5">
          <Avatar initials={initials} seed={email} size="sm" />
          {name} {you && <Chip variant="accent">You</Chip>}
        </div>
      </td>
      <td className="px-3 py-3 text-[var(--color-text-muted)]">{email}</td>
      <td className="px-3 py-3">{role}</td>
      <td className="px-3 py-3 text-[var(--color-text-muted)] text-[12px]">{active}</td>
      <td className="px-3 py-3"><a href="#" className="text-[var(--color-text-muted)] text-[12px] hover:text-[var(--color-text)]">Edit</a></td>
    </tr>
  );
}

function ApiKeyRow({ name, hash, meta, status }: { name: string; hash: string; meta: string; status: "active" | "stale" }) {
  return (
    <div className="grid grid-cols-[1fr_auto_auto] gap-3 items-center p-3 border border-[var(--color-border)] rounded-xl">
      <div>
        <strong className="text-[13px]">{name}</strong>
        <div className="flex items-center gap-2 mt-1.5 flex-wrap">
          <code className="text-[12px] bg-[var(--color-surface-muted)] px-2 py-0.5 rounded font-mono">{hash}</code>
          <span className="text-[11px] text-[var(--color-text-muted)]">{meta}</span>
        </div>
      </div>
      {status === "active" ? <Chip variant="accent" dot>Active</Chip> : <Chip variant="warn" dot>Stale</Chip>}
      <Button variant="ghost" size="xs">Revoke</Button>
    </div>
  );
}

function Integration({ name, desc, connected }: { name: string; desc: string; connected: boolean }) {
  return (
    <div className="grid grid-cols-[1fr_auto_auto] gap-3 items-center p-3 border border-[var(--color-border)] rounded-xl">
      <div>
        <strong className="text-[13px]">{name}</strong>
        <div className="text-[11px] text-[var(--color-text-muted)] mt-0.5">{desc}</div>
      </div>
      {connected
        ? <Chip variant="accent" dot>Connected</Chip>
        : <Chip variant="muted"  dot>Not connected</Chip>}
      <Button variant="ghost" size="xs">{connected ? "Configure" : "Connect"}</Button>
    </div>
  );
}

function AuditItem({ text, time, warn }: { text: React.ReactNode; time: string; warn?: boolean }) {
  return (
    <div className="flex gap-3 items-start">
      <span className={`mt-1.5 w-2 h-2 rounded-full ${warn ? "bg-[var(--color-warn)]" : "bg-[var(--color-accent)]"} shrink-0`} />
      <div className="flex-1 text-[13px]">
        {text}
        <small className="block text-[var(--color-text-muted)] text-[11px] mt-0.5">{time}</small>
      </div>
    </div>
  );
}
