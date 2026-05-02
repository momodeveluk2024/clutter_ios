"use client";

import { usePathname } from "next/navigation";
import Link from "next/link";
import { Search } from "lucide-react";

const titles: Record<string, string> = {
  "/":           "Overview",
  "/foods":      "Foods",
  "/nutrients":  "Nutrients",
  "/users":      "Users",
  "/meal-logs":  "Meal logs",
  "/reminders":  "Reminders",
  "/settings":   "Settings",
};

export function Topbar() {
  const pathname = usePathname();
  if (pathname === "/login") return null;

  // Build a simple breadcrumb
  const crumbs: { label: string; href?: string }[] = [{ label: "Admin", href: "/" }];
  const segments = pathname.split("/").filter(Boolean);
  if (segments.length === 0) {
    crumbs[0] = { label: "Overview" };
  } else {
    const first = `/${segments[0]}`;
    crumbs.push({ label: titles[first] ?? segments[0], href: segments.length > 1 ? first : undefined });
    if (segments.length > 1) {
      crumbs.push({ label: segments.slice(1).join(" / ") });
    }
  }

  return (
    <header className="h-16 px-8 bg-[var(--color-bg)] border-b border-[var(--color-border)] flex items-center gap-4 sticky top-0 z-10">
      <nav className="text-[13px] flex items-center gap-1.5">
        {crumbs.map((c, i) => (
          <span key={i} className="flex items-center gap-1.5">
            {c.href ? (
              <Link href={c.href} className="text-[var(--color-text-muted)] hover:text-[var(--color-text)]">
                {c.label}
              </Link>
            ) : (
              <span className="font-semibold text-[var(--color-text)]">{c.label}</span>
            )}
            {i < crumbs.length - 1 && <span className="text-[var(--color-text-muted)]">/</span>}
          </span>
        ))}
      </nav>

      <div className="flex-1 max-w-md ml-8 relative">
        <Search size={14} className="absolute left-3.5 top-1/2 -translate-y-1/2 text-[var(--color-text-muted)]" />
        <input
          placeholder="Search foods, users, logs…"
          className="w-full h-9 pl-10 pr-12 bg-[var(--color-surface)] border border-[var(--color-border)] rounded-[10px] text-[13px] focus:outline-none focus:border-[var(--color-accent)] focus:ring-2 focus:ring-[var(--color-accent-soft)]"
        />
        <span className="absolute right-2.5 top-1/2 -translate-y-1/2 text-[10px] font-semibold text-[var(--color-text-muted)] bg-[var(--color-surface-muted)] border border-[var(--color-border)] px-1.5 py-0.5 rounded">
          ⌘K
        </span>
      </div>
    </header>
  );
}
