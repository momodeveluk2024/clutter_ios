import { api } from "@/lib/api";
import { PageHeader } from "@/components/ui/PageHeader";
import { Button } from "@/components/ui/Button";
import { Chip } from "@/components/ui/Chip";
import { NutrientPill } from "@/components/ui/NutrientPill";
import { Table, THead, TH, TBody, TRow, TD } from "@/components/ui/Table";
import { Plus, Download } from "lucide-react";
import { createNutrient, updateNutrient } from "./actions";

export const dynamic = "force-dynamic";

export default async function NutrientsPage() {
  const nutrients = await api.listNutrients();
  const vits = nutrients.filter((n) => n.group === "vitamin");
  const mins = nutrients.filter((n) => n.group === "mineral");
  const macs = nutrients.filter((n) => n.group === "macro");

  return (
    <div className="p-8">
      <PageHeader
        title="Nutrients & DRI"
        sub={`${nutrients.length} nutrients tracked - adult DRI values from the backend`}
        actions={
          <>
            <Button variant="ghost" size="sm" href="/api/admin/export/nutrients"><Download size={12} /> Export</Button>
          </>
        }
      />

      <div className="flex flex-wrap gap-2 mb-5">
        <Chip variant="accent">All <span className="opacity-70 ml-1">{nutrients.length}</span></Chip>
        <Chip>Vitamins <span className="text-[var(--color-text-muted)] ml-1">{vits.length}</span></Chip>
        <Chip>Minerals <span className="text-[var(--color-text-muted)] ml-1">{mins.length}</span></Chip>
        <Chip>Macros <span className="text-[var(--color-text-muted)] ml-1">{macs.length}</span></Chip>
      </div>

      <form action={createNutrient} className="mb-5 grid grid-cols-1 md:grid-cols-[90px_1fr_90px_120px_120px_auto] gap-2 rounded-[18px] border border-[var(--color-border)] bg-[var(--color-surface)] p-3">
        <input name="code" className="input" placeholder="Code" required />
        <input name="name" className="input" placeholder="Name" required />
        <input name="unit" className="input" placeholder="Unit" required />
        <select name="group" className="input" defaultValue="vitamin">
          <option value="vitamin">Vitamin</option><option value="mineral">Mineral</option><option value="macro">Macro</option>
        </select>
        <input name="driAdult" type="number" step="0.1" className="input" placeholder="Adult DRI" />
        <Button variant="primary" size="sm" type="submit"><Plus size={14} /> New nutrient</Button>
      </form>

      <Table>
        <THead>
          <TH className="w-16">Code</TH>
          <TH>Name</TH>
          <TH>Group</TH>
          <TH>Unit</TH>
          <TH>DRI (adult)</TH>
          <TH>Foods using</TH>
          <TH>Updated</TH>
          <TH><span className="sr-only">Actions</span></TH>
        </THead>
        <TBody>
          {nutrients.map((n, i) => (
            <TRow key={n.id} index={i}>
              <TD><NutrientPill code={n.code} size="sm" /></TD>
              <TD className="font-semibold">{n.name}</TD>
              <TD className="capitalize text-[var(--color-text-muted)]">{n.group}</TD>
              <TD className="text-[var(--color-text-muted)]">{n.unit}</TD>
              <TD className="tabular"><strong>{n.driAdult}</strong> <span className="text-[var(--color-text-muted)]">{n.unit}</span></TD>
              <TD className="tabular">{n.foodCount}</TD>
              <TD className="text-[var(--color-text-muted)] text-[12px]">{n.updatedAt}</TD>
              <TD>
                <form action={updateNutrient.bind(null, n.code)} className="flex gap-1 items-center">
                  <input type="hidden" name="code" value={n.code} />
                  <input type="hidden" name="name" value={n.name} />
                  <input type="hidden" name="unit" value={n.unit} />
                  <input type="hidden" name="group" value={n.group} />
                  <input name="driAdult" type="number" step="0.1" defaultValue={n.driAdult} className="h-8 w-24 px-2 bg-white border border-[var(--color-border)] rounded-lg text-[12px]" />
                  <Button variant="ghost" size="xs" type="submit">Save</Button>
                </form>
              </TD>
            </TRow>
          ))}
        </TBody>
      </Table>
      <style>{`.input { height: 36px; padding: 0 10px; background: white; border: 1px solid var(--color-border); border-radius: 10px; font-size: 12px; }`}</style>
    </div>
  );
}
