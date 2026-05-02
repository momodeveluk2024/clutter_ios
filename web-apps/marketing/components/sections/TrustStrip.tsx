import { trust } from "@/lib/copy";

export function TrustStrip() {
  return (
    <div className="border-y border-[var(--color-border)] bg-[var(--color-bg)]">
      <div className="mx-auto max-w-7xl px-6 py-3">
        <ul className="flex flex-wrap gap-x-12 gap-y-2 justify-center text-xs text-[var(--color-text-muted)]">
          {trust.map((t) => (
            <li key={t} className="flex items-center gap-3">
              <span className="w-1 h-1 rounded-full bg-[var(--color-text-muted)]" />
              {t}
            </li>
          ))}
        </ul>
      </div>
    </div>
  );
}
