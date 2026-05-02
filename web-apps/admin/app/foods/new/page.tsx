import { PageHeader } from "@/components/ui/PageHeader";
import { Button } from "@/components/ui/Button";
import { Card } from "@/components/ui/Card";
import { createFood } from "../[id]/actions";

export const dynamic = "force-dynamic";

export default function NewFoodPage() {
  return (
    <div className="p-8 max-w-4xl">
      <PageHeader
        title="New food"
        sub="Create a database-backed catalog food for Flutter and the admin dashboard."
        actions={<Button variant="ghost" size="sm" href="/foods">Cancel</Button>}
      />
      <Card>
        <form action={createFood} className="space-y-5">
          <div className="grid grid-cols-2 gap-4">
            <Field label="Name"><input name="name" className="input" required /></Field>
            <Field label="Brand"><input name="brand" className="input" /></Field>
          </div>
          <div className="grid grid-cols-3 gap-4">
            <Field label="Category"><input name="category" className="input" defaultValue="general" required /></Field>
            <Field label="Serving (g)"><input name="servingSizeG" type="number" step="0.1" className="input" defaultValue="100" required /></Field>
            <Field label="Source"><input name="source" className="input" defaultValue="manual" /></Field>
          </div>
          <div className="grid grid-cols-2 gap-4">
            <Field label="Barcode"><input name="barcode" className="input" /></Field>
            <Field label="Image URL"><input name="imageUrl" className="input" placeholder="https://..." /></Field>
          </div>
          <label className="inline-flex items-center gap-2 text-[13px]">
            <input name="verified" type="checkbox" className="accent-[var(--color-accent)] w-4 h-4" />
            Verified by admin
          </label>
          <div className="border border-[var(--color-border)] rounded-xl p-4">
            <h3 className="text-sm font-semibold mb-3">Nutrients per 100g</h3>
            {[0, 1, 2].map((row) => (
              <div key={row} className="grid grid-cols-[1fr_1fr] gap-3 mb-3 last:mb-0">
                <input name="nutrientCode" className="input" placeholder="Code, e.g. D" />
                <input name="nutrientAmount" type="number" step="0.1" className="input" placeholder="Amount" />
              </div>
            ))}
          </div>
          <div className="flex justify-end">
            <Button variant="primary" size="sm" type="submit">Create food</Button>
          </div>
        </form>
      </Card>
      <style>{`
        .input { width: 100%; height: 40px; padding: 0 14px; background: white; border: 1px solid var(--color-border); border-radius: 12px; color: var(--color-text); font-size: 13px; }
      `}</style>
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
