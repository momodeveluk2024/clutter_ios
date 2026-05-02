"use client";

import { useEffect, useRef, useState } from "react";
import { useInView } from "motion/react";
import { ArrowUpRight, ArrowDownRight } from "lucide-react";
import { Card } from "./Card";
import { fmtNum } from "@/lib/utils";
import { cn } from "@/lib/utils";

type Props = {
  label: string;
  value: number;
  decimals?: number;
  suffix?: string;
  delta?: { value: number; suffix?: string; up?: boolean };
  emphasisColor?: string; // override color of value text
  helper?: string;
};

export function KpiCard({ label, value, decimals = 0, suffix, delta, emphasisColor, helper }: Props) {
  const ref = useRef<HTMLDivElement>(null);
  const inView = useInView(ref, { once: true, amount: 0.5 });
  const [v, setV] = useState(0);

  useEffect(() => {
    if (!inView) return;
    const start = performance.now();
    const dur = 1200;
    let raf = 0;
    const tick = (t: number) => {
      const p = Math.min(1, (t - start) / dur);
      const eased = 1 - Math.pow(1 - p, 3);
      setV(value * eased);
      if (p < 1) raf = requestAnimationFrame(tick);
    };
    raf = requestAnimationFrame(tick);
    return () => cancelAnimationFrame(raf);
  }, [inView, value]);

  return (
    <Card>
      <div ref={ref}>
        <p className="eyebrow">{label}</p>
        <div
          className="mt-2 text-[28px] font-bold tracking-tight tabular leading-none"
          style={emphasisColor ? { color: emphasisColor } : undefined}
        >
          {fmtNum(v, decimals)}
          {suffix && <span className="text-[var(--color-text-muted)] text-[16px] ml-1">{suffix}</span>}
        </div>
        {delta && (
          <p className={cn(
            "mt-3 text-[12px] inline-flex items-center gap-1 font-medium",
            delta.up ? "text-[var(--color-accent-deep)]" : "text-[var(--color-err)]"
          )}>
            {delta.up ? <ArrowUpRight size={12} /> : <ArrowDownRight size={12} />}
            <span className="tabular">{delta.value}%</span>
            {delta.suffix && <span className="text-[var(--color-text-muted)] ml-0.5">{delta.suffix}</span>}
          </p>
        )}
        {helper && !delta && (
          <p className="mt-3 text-[12px] text-[var(--color-text-muted)]">{helper}</p>
        )}
      </div>
    </Card>
  );
}
