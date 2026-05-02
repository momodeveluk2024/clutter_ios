import { api } from "@/lib/api";
import { PageHeader } from "@/components/ui/PageHeader";
import { Button } from "@/components/ui/Button";
import { Card } from "@/components/ui/Card";
import { Chip } from "@/components/ui/Chip";
import { KpiCard } from "@/components/ui/KpiCard";
import { Table, THead, TH, TBody, TRow, TD } from "@/components/ui/Table";
import { Download, Plus } from "lucide-react";
import { createReminderTemplate, updateReminderTemplate } from "./actions";

export const dynamic = "force-dynamic";

export default async function RemindersPage() {
  const templates = await api.listReminderTemplates();

  return (
    <div className="p-8">
      <PageHeader
        title="Reminders"
        sub="Database-backed reminder templates"
        actions={<Button variant="ghost" size="sm" href="/api/admin/export/reminder-templates"><Download size={12} /> Export</Button>}
      />

      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 mb-6">
        <KpiCard label="Templates" value={templates.length} helper="loaded from backend" />
        <KpiCard label="Active templates" value={templates.filter((t) => t.active).length} />
        <KpiCard label="Paused" value={templates.filter((t) => !t.active).length} />
        <KpiCard label="Sent (7d)" value={templates.reduce((sum, t) => sum + t.sent7d, 0)} />
      </div>

      <Card className="mb-4">
        <form action={createReminderTemplate} className="grid grid-cols-1 md:grid-cols-[1fr_1fr_1fr_1fr_auto_auto] gap-2 items-end">
          <Field label="Title"><input name="title" className="input" required /></Field>
          <Field label="Body"><input name="body" className="input" /></Field>
          <Field label="Trigger"><input name="trigger" className="input" placeholder="Daily 09:00 local" required /></Field>
          <Field label="Audience"><input name="audience" className="input" defaultValue="all" required /></Field>
          <label className="inline-flex items-center gap-2 h-9 text-[12px]"><input name="active" type="checkbox" defaultChecked /> Active</label>
          <Button variant="primary" size="sm" type="submit"><Plus size={14} /> New template</Button>
        </form>
      </Card>

      <Table>
        <THead>
          <TH>Title</TH>
          <TH>Trigger</TH>
          <TH>Audience</TH>
          <TH>Sent (7d)</TH>
          <TH>Status</TH>
          <TH>Save</TH>
        </THead>
        <TBody>
          {templates.map((t, i) => (
            <TRow key={t.id} index={i}>
              <TD>
                <form id={`template-${t.id}`} action={updateReminderTemplate.bind(null, t.id)} className="space-y-2">
                  <input name="title" className="input" defaultValue={t.title} />
                  <input name="body" className="input" defaultValue={t.body} />
                </form>
              </TD>
              <TD><input form={`template-${t.id}`} name="trigger" className="input" defaultValue={t.trigger} /></TD>
              <TD><input form={`template-${t.id}`} name="audience" className="input" defaultValue={t.audience} /></TD>
              <TD className="tabular">{t.sent7d.toLocaleString()}</TD>
              <TD>
                <label className="inline-flex items-center gap-2 text-[12px]">
                  <input form={`template-${t.id}`} name="active" type="checkbox" defaultChecked={t.active} />
                  {t.active ? <Chip variant="accent" dot>Active</Chip> : <Chip variant="muted" dot>Paused</Chip>}
                </label>
              </TD>
              <TD><Button form={`template-${t.id}`} variant="ghost" size="xs" type="submit">Save</Button></TD>
            </TRow>
          ))}
        </TBody>
      </Table>
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
