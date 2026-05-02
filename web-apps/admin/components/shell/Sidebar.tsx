"use client";

import Image from "next/image";
import Link from "next/link";
import { usePathname } from "next/navigation";
import { motion } from "motion/react";
import {
  LayoutDashboard, Apple, Sparkles, BookOpen, Users, Bell, Settings, Bot, Activity,
} from "lucide-react";
import { cn } from "@/lib/utils";

const groups = [
  {
    items: [
      { href: "/", label: "Overview", icon: LayoutDashboard },
    ],
  },
  {
    title: "Catalog",
    items: [
      { href: "/foods",     label: "Foods",     icon: Apple },
      { href: "/nutrients", label: "Nutrients", icon: Sparkles                },
    ],
  },
  {
    title: "Activity",
    items: [
      { href: "/meal-logs", label: "Meal logs", icon: BookOpen },
      { href: "/users",     label: "Users",     icon: Users    },
      { href: "/reminders", label: "Reminders", icon: Bell     },
    ],
  },
  {
    title: "AI",
    items: [
      { href: "/ai/estimates", label: "Estimates", icon: Bot      },
      { href: "/ai/usage",     label: "Usage",     icon: Activity },
    ],
  },
];

export function Sidebar() {
  const pathname = usePathname();

  if (pathname === "/login") return null;

  return (
    <aside className="w-[240px] border-r border-[var(--color-border)] bg-[var(--color-surface)] flex flex-col sticky top-0 h-screen">
      <div className="px-4 pt-5 pb-4">
        <Link href="/" className="flex items-center gap-2.5 group">
          <span className="relative w-9 h-9 grid place-items-center group-hover:scale-95 transition-transform">
            <Image
              src="/logo.png"
              alt="Nutrimate logo"
              width={36}
              height={36}
              className="object-contain"
              priority
            />
          </span>
          <span className="font-semibold tracking-tight">Nutrimate Admin</span>
        </Link>
      </div>

      <nav className="flex-1 px-3 overflow-y-auto">
        {groups.map((g, gi) => (
          <div key={gi} className="mb-2">
            {g.title && (
              <p className="eyebrow px-3 pt-3 pb-1.5 text-[var(--color-text-muted)]">{g.title}</p>
            )}
            {g.items.map((item) => {
              const active = pathname === item.href || (item.href !== "/" && pathname.startsWith(item.href));
              const Icon = item.icon;
              return (
                <Link
                  key={item.href}
                  href={item.href}
                  className={cn(
                    "relative flex items-center gap-3 px-3 py-2 rounded-lg text-[13px] font-medium transition-colors",
                    active
                      ? "text-[var(--color-accent-deep)]"
                      : "text-[var(--color-text)] hover:bg-[var(--color-surface-muted)]",
                  )}
                >
                  {active && (
                    <motion.span
                      layoutId="active-pill"
                      className="absolute inset-0 rounded-lg bg-[var(--color-accent-soft)]"
                      transition={{ type: "spring", stiffness: 500, damping: 35 }}
                    />
                  )}
                  <Icon size={16} strokeWidth={1.8} className="relative" />
                  <span className="relative flex-1">{item.label}</span>
                </Link>
              );
            })}
          </div>
        ))}
      </nav>

      <div className="px-3 pb-3">
        <Link
          href="/settings"
          className={cn(
            "relative flex items-center gap-3 px-3 py-2 rounded-lg text-[13px] font-medium transition-colors",
            pathname.startsWith("/settings")
              ? "text-[var(--color-accent-deep)] bg-[var(--color-accent-soft)]"
              : "text-[var(--color-text)] hover:bg-[var(--color-surface-muted)]",
          )}
        >
          <Settings size={16} strokeWidth={1.8} />
          <span className="flex-1">Settings</span>
        </Link>

        <div className="mt-3 pt-3 border-t border-[var(--color-border)] flex items-center gap-2.5">
          <div className="grid place-items-center w-8 h-8 rounded-full bg-[var(--color-accent)] text-white text-xs font-bold">
            JM
          </div>
          <div className="flex-1 min-w-0">
            <p className="text-[12px] font-semibold leading-tight truncate">Jane Miller</p>
            <p className="text-[10px] text-[var(--color-text-muted)] leading-tight truncate">jane@nv.app</p>
          </div>
        </div>
      </div>
    </aside>
  );
}
