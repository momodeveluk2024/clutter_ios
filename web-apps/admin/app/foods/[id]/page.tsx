import { api } from "@/lib/api";
import { PageHeader } from "@/components/ui/PageHeader";
import { Button } from "@/components/ui/Button";
import { Card } from "@/components/ui/Card";
import { Chip } from "@/components/ui/Chip";
import { NutrientPill } from "@/components/ui/NutrientPill";
import { Plus } from "lucide-react";
import { deleteFood, saveFood, uploadFoodImage } from "./actions";

export const dynamic = "force-dynamic";

export default async function FoodEditPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  const food = await api.getFood(id);
  const saveAction = saveFood.bind(null, id);
  const deleteAction = deleteFood.bind(null, id);
  const uploadAction = uploadFoodImage.bind(null, id);

  return (
    <div className="p-8 max-w-5xl">
      <PageHeader
        title={food.name}
        sub={`id: ${food.id} · ${food.brand ? `brand: ${food.brand} · ` : ""}updated recently`}
        actions={
          <>
            <Chip variant={food.verified ? "accent" : "warn"} dot>
              {food.verified ? "Verified" : "Pending"}
            </Chip>
            <Button variant="ghost" size="sm" href="/foods">Discard</Button>
          </>
        }
      />

      <form action={saveAction}>
      <Card>
        {/* Basics */}
        <FormSection
          title="Basics"
          desc="Name and identification. Used everywhere foods are searched or displayed."
        >
          <Field label="Name">
            <input name="name" className="input" defaultValue={food.name} />
          </Field>
          <div className="grid grid-cols-2 gap-4">
            <Field label="Brand (optional)">
              <input name="brand" className="input" defaultValue={food.brand ?? ""} placeholder="e.g. Lightlife" />
            </Field>
            <Field label="Barcode (optional)">
              <input name="barcode" className="input" defaultValue={food.barcode ?? ""} placeholder="EAN-13 / UPC-A" />
            </Field>
          </div>
        </FormSection>

        {/* Categorization */}
        <FormSection
          title="Categorization"
          desc="How the food is grouped in search and the home explore tab."
        >
          <div className="grid grid-cols-2 gap-4">
            <Field label="Category">
              <select name="category" className="input" defaultValue={food.category}>
                <option>vegetables</option><option>fruits</option><option>seafood</option>
                <option>dairy</option><option>nuts</option><option>legumes</option>
                <option>grains</option><option>general</option>
              </select>
            </Field>
            <Field label="Source">
              <select name="source" className="input" defaultValue={food.source}>
                <option value="seed">seed (USDA)</option>
                <option value="manual">manual</option>
                <option value="user_submitted">user_submitted</option>
              </select>
            </Field>
          </div>
          <div className="grid grid-cols-2 gap-4">
            <Field label="Default serving (g)" help="Used as the pre-filled portion when users log this food.">
              <input name="servingSizeG" type="number" className="input tabular" defaultValue={food.servingSizeG} />
            </Field>
            <Field label="Verification" help="Unverified foods are flagged in the mobile UI.">
              <label className="inline-flex items-center gap-2 h-10 text-[13px]">
                <input name="verified" type="checkbox" defaultChecked={food.verified} className="accent-[var(--color-accent)] w-4 h-4" />
                Verified by admin
              </label>
            </Field>
          </div>
        </FormSection>

        <FormSection
          title="Image"
          desc="Food photos are stored on the food row and returned to Flutter as image_url."
        >
          {food.imageUrl && (
            // eslint-disable-next-line @next/next/no-img-element
            <img src={food.imageUrl} alt={food.name} className="w-36 h-24 object-cover rounded-xl border border-[var(--color-border)]" />
          )}
          <Field label="Image URL">
            <input name="imageUrl" className="input" defaultValue={food.imageUrl ?? ""} placeholder="https://..." />
          </Field>
        </FormSection>

        {/* Nutrients */}
        <FormSection
          title="Nutrients"
          desc={<>Amounts <strong>per 100 g</strong>. Stored in <code className="text-[12px] bg-[var(--color-surface-muted)] px-1.5 py-0.5 rounded">food_nutrients</code> and used to compute daily totals.</>}
          actions={<span className="inline-flex items-center gap-1 text-[11px] text-[var(--color-text-muted)]"><Plus size={11} /> Add a row below and save</span>}
        >
          <div className="border border-[var(--color-border)] rounded-xl overflow-hidden">
            <table className="w-full text-[13px]">
              <thead className="border-b border-[var(--color-border)]">
                <tr>
                  <th className="px-3 py-2.5 text-left text-[10px] font-bold tracking-[0.08em] uppercase text-[var(--color-text-muted)] w-20">Code</th>
                  <th className="px-3 py-2.5 text-left text-[10px] font-bold tracking-[0.08em] uppercase text-[var(--color-text-muted)]">Nutrient</th>
                  <th className="px-3 py-2.5 text-left text-[10px] font-bold tracking-[0.08em] uppercase text-[var(--color-text-muted)] w-44">Amount / 100g</th>
                  <th className="px-3 py-2.5 text-left text-[10px] font-bold tracking-[0.08em] uppercase text-[var(--color-text-muted)] w-20">Unit</th>
                  <th className="w-10"></th>
                </tr>
              </thead>
              <tbody>
                {food.nutrients.map((n) => (
                  <tr key={n.code} className="border-b border-[var(--color-border)] last:border-0">
                    <td className="px-3 py-3"><input name="nutrientCode" className="input h-8 tabular w-full" defaultValue={n.code} /></td>
                    <td className="px-3 py-3">{n.name}</td>
                    <td className="px-3 py-3">
                      <input name="nutrientAmount" type="number" step="0.1" defaultValue={n.amount} className="input h-8 tabular w-full" />
                    </td>
                    <td className="px-3 py-3 text-[var(--color-text-muted)]">{n.unit}</td>
                    <td className="px-3 py-3"><NutrientPill code={n.code} size="sm" /></td>
                  </tr>
                ))}
                <tr className="border-b border-[var(--color-border)] last:border-0">
                  <td className="px-3 py-3"><input name="nutrientCode" className="input h-8 tabular w-full" placeholder="Code" /></td>
                  <td className="px-3 py-3 text-[var(--color-text-muted)]">New nutrient</td>
                  <td className="px-3 py-3"><input name="nutrientAmount" type="number" step="0.1" className="input h-8 tabular w-full" placeholder="0" /></td>
                  <td className="px-3 py-3 text-[var(--color-text-muted)]">lookup</td>
                  <td className="px-3 py-3"></td>
                </tr>
              </tbody>
            </table>
          </div>
          <p className="text-[11px] text-[var(--color-text-muted)] mt-2.5">{food.nutrients.length} nutrients · last edited recently · revision 4</p>
        </FormSection>
        <div className="flex justify-end">
          <Button variant="primary" size="sm" type="submit">Save changes</Button>
        </div>
      </Card>
      </form>

      <Card className="mt-4">
        <form action={uploadAction} className="flex items-end gap-3">
          <Field label="Upload image file">
            <input name="image" type="file" accept="image/*" className="input py-2" />
          </Field>
          <Button variant="ghost" size="sm" type="submit">Upload image</Button>
        </form>
      </Card>

      {/* Danger zone */}
      <Card className="mt-4 !border-[#F0D2D2]">
        <div className="flex items-center justify-between gap-4">
          <div>
            <h3 className="text-lg font-semibold tracking-tight text-[var(--color-err)]">Danger zone</h3>
            <p className="text-[12px] text-[var(--color-text-muted)] mt-1">
              Soft-delete keeps history but hides this food from users. Hard delete is permanent.
            </p>
          </div>
          <form action={deleteAction}>
            <Button variant="danger" size="sm" type="submit">Soft-delete</Button>
          </form>
        </div>
      </Card>

      {/* small inline styles for the .input utility */}
      <style>{`
        .input {
          width: 100%; height: 40px; padding: 0 14px;
          background: white;
          border: 1px solid var(--color-border);
          border-radius: 12px;
          color: var(--color-text); font-size: 13px;
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

function FormSection({
  title, desc, actions, children,
}: { title: string; desc: React.ReactNode; actions?: React.ReactNode; children: React.ReactNode }) {
  return (
    <section className="grid grid-cols-1 md:grid-cols-[240px_1fr] gap-x-12 gap-y-6 pb-7 mb-7 border-b border-[var(--color-border)] last:border-0 last:pb-0 last:mb-0">
      <div>
        <h3 className="text-lg font-semibold tracking-tight">{title}</h3>
        <p className="text-[13px] text-[var(--color-text-muted)] mt-1 leading-relaxed">{desc}</p>
        {actions && <div className="mt-3">{actions}</div>}
      </div>
      <div className="space-y-4">{children}</div>
    </section>
  );
}

function Field({ label, children, help }: { label: string; children: React.ReactNode; help?: string }) {
  return (
    <div>
      <label className="block text-[12px] font-semibold mb-1.5">{label}</label>
      {children}
      {help && <p className="text-[11px] text-[var(--color-text-muted)] mt-1">{help}</p>}
    </div>
  );
}
