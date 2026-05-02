import { api } from "@/lib/api";
import { PageHeader } from "@/components/ui/PageHeader";
import { Button } from "@/components/ui/Button";
import { Chip } from "@/components/ui/Chip";
import { NutrientPill } from "@/components/ui/NutrientPill";
import { Table, THead, TH, TBody, TRow, TD } from "@/components/ui/Table";
import { fmtRelative } from "@/lib/utils";
import { Plus, Download, Upload } from "lucide-react";

export const dynamic = "force-dynamic";

export default async function FoodsPage({ searchParams }: { searchParams: Promise<{ q?: string; category?: string; verified?: string }> }) {
  const filters = await searchParams;
  const [foods, overview] = await Promise.all([api.listFoods(filters), api.overview()]);
  const totalFoods = overview.kpis.foodsInCatalog.value;
  const pendingFoods = overview.kpis.pendingVerification.value;
  const verifiedFoods = Math.max(totalFoods - pendingFoods, 0);

  return (
    <div className="p-8">
      <PageHeader
        title="Foods"
        sub={`${totalFoods} foods - ${pendingFoods} pending verification`}
        actions={
          <>
            <Button variant="ghost" size="sm" href="/api/admin/export/foods"><Download size={12} /> Export CSV</Button>
            <Button variant="primary" size="sm" href="/foods/new"><Plus size={14} /> New food</Button>
          </>
        }
      />

      <div className="flex flex-wrap gap-2 mb-5">
        <Chip variant="accent">All <span className="opacity-70 ml-1">{totalFoods}</span></Chip>
        <Chip>Verified <span className="text-[var(--color-text-muted)] ml-1">{verifiedFoods}</span></Chip>
        <Chip>Pending <span className="text-[var(--color-text-muted)] ml-1">{pendingFoods}</span></Chip>
        <Chip>User-submitted <span className="text-[var(--color-text-muted)] ml-1">{foods.filter((f) => f.source === "user_submitted").length}</span></Chip>
      </div>

      <form className="rounded-t-[18px] border border-b-0 border-[var(--color-border)] bg-[var(--color-surface)] p-3 flex gap-2 items-center" action="/foods">
        <input
          name="q"
          defaultValue={filters.q ?? ""}
          placeholder="Filter by name or barcode..."
          className="h-9 px-3 bg-white border border-[var(--color-border)] rounded-[10px] text-[13px] flex-1 max-w-xs focus:outline-none focus:border-[var(--color-accent)] focus:ring-2 focus:ring-[var(--color-accent-soft)]"
        />
        <select name="category" defaultValue={filters.category ?? ""} className="h-9 px-3 bg-white border border-[var(--color-border)] rounded-[10px] text-[13px]">
          <option value="">All categories</option>
          <option value="vegetables">Vegetables</option><option value="fruits">Fruits</option><option value="seafood">Seafood</option>
          <option value="dairy">Dairy</option><option value="nuts">Nuts</option><option value="legumes">Legumes</option><option value="grains">Grains</option>
        </select>
        <select name="verified" defaultValue={filters.verified ?? ""} className="h-9 px-3 bg-white border border-[var(--color-border)] rounded-[10px] text-[13px]">
          <option value="">All status</option><option value="true">Verified</option><option value="false">Pending</option>
        </select>
        <Button variant="ghost" size="sm" type="submit"><Upload size={12} /> Apply</Button>
      </form>

      <Table className="rounded-t-none border-t-0">
        <THead>
          <TH className="w-8"><input type="checkbox" /></TH>
          <TH>Name</TH>
          <TH>Category</TH>
          <TH>Serving</TH>
          <TH>Nutrients</TH>
          <TH>Source</TH>
          <TH>Status</TH>
          <TH>Updated</TH>
          <TH><span className="sr-only">Actions</span></TH>
        </THead>
        <TBody>
          {foods.map((f, i) => (
            <TRow key={f.id} index={i}>
              <TD><input type="checkbox" /></TD>
              <TD>
                <a href={`/foods/${f.id}`} className="font-semibold text-[var(--color-text)] hover:text-[var(--color-accent-deep)]">
                  {f.name}
                </a>
                <div className="text-[11px] text-[var(--color-text-muted)] mt-0.5">
                  id: {f.id}{f.brand ? ` - brand: ${f.brand}` : ""}
                </div>
              </TD>
              <TD className="capitalize text-[var(--color-text-muted)]">{f.category}</TD>
              <TD className="tabular text-[var(--color-text-muted)]">{f.servingSizeG} g</TD>
              <TD>
                <div className="flex gap-1">
                  {f.nutrients.slice(0, 3).map((n) => (
                    <NutrientPill key={n.code} code={n.code} size="sm" />
                  ))}
                  {f.nutrients.length > 3 && (
                    <span className="text-[10px] text-[var(--color-text-muted)] self-center ml-1">+{f.nutrients.length - 3}</span>
                  )}
                </div>
              </TD>
              <TD className="text-[var(--color-text-muted)] text-[12px]">
                {f.source === "seed" ? "USDA seed" : f.source === "manual" ? "Manual" : "User submitted"}
              </TD>
              <TD>
                {f.verified
                  ? <Chip variant="accent" dot>Verified</Chip>
                  : <Chip variant="warn" dot>Pending</Chip>}
              </TD>
              <TD className="text-[var(--color-text-muted)] text-[12px]">{fmtRelative(f.updatedAt)}</TD>
              <TD>
                <a href={`/foods/${f.id}`} className="text-[var(--color-text-muted)] text-[12px] hover:text-[var(--color-text)]">Edit</a>
              </TD>
            </TRow>
          ))}
        </TBody>
      </Table>

      <div className="px-4 py-3 border border-t-0 border-[var(--color-border)] bg-[var(--color-surface)] rounded-b-[18px] flex items-center justify-between text-[12px] text-[var(--color-text-muted)]">
        <span>Showing 1-{foods.length} of {totalFoods}</span>
        <div className="flex gap-1">
          <button className="w-7 h-7 grid place-items-center rounded-md hover:bg-[var(--color-surface-muted)]">&lt;</button>
          <button className="w-7 h-7 grid place-items-center rounded-md bg-[var(--color-accent)] text-white">1</button>
          <button className="w-7 h-7 grid place-items-center rounded-md hover:bg-[var(--color-surface-muted)]">2</button>
          <button className="w-7 h-7 grid place-items-center rounded-md hover:bg-[var(--color-surface-muted)]">3</button>
          <span className="px-2 text-[var(--color-text-muted)]">...</span>
          <button className="w-7 h-7 grid place-items-center rounded-md hover:bg-[var(--color-surface-muted)]">&gt;</button>
        </div>
      </div>
    </div>
  );
}
