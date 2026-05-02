import { type ReactNode } from "react";

export function PageHeader({
  title,
  sub,
  actions,
}: {
  title: string;
  sub?: string;
  actions?: ReactNode;
}) {
  return (
    <div className="flex flex-wrap items-start justify-between gap-4 mb-8">
      <div>
        <h1 className="text-[26px] font-bold tracking-tight leading-tight">{title}</h1>
        {sub && <p className="text-[var(--color-text-muted)] mt-1 text-[14px]">{sub}</p>}
      </div>
      {actions && <div className="flex items-center gap-2">{actions}</div>}
    </div>
  );
}
