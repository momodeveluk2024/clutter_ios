"use client";

import {
  ResponsiveContainer, AreaChart, Area, XAxis, YAxis, CartesianGrid, Tooltip,
} from "recharts";

type Datum = { day: string; logs: number };

export function LogsChart({ data }: { data: Datum[] }) {
  return (
    <div className="h-[260px] w-full">
      <ResponsiveContainer width="100%" height="100%">
        <AreaChart data={data} margin={{ top: 10, right: 10, left: -20, bottom: 0 }}>
          <defs>
            <linearGradient id="logArea" x1="0" y1="0" x2="0" y2="1">
              <stop offset="0%" stopColor="#2F7D4A" stopOpacity={0.32} />
              <stop offset="100%" stopColor="#2F7D4A" stopOpacity={0.04} />
            </linearGradient>
          </defs>
          <CartesianGrid vertical={false} strokeDasharray="3 3" />
          <XAxis
            dataKey="day"
            tickLine={false}
            axisLine={false}
            interval="preserveStartEnd"
            minTickGap={28}
            tick={{ fontSize: 11 }}
          />
          <YAxis tickLine={false} axisLine={false} width={56} tickFormatter={(v) => Intl.NumberFormat("en", { notation: "compact" }).format(v)} />
          <Tooltip
            cursor={{ stroke: "#2F7D4A", strokeOpacity: 0.2, strokeWidth: 2 }}
            contentStyle={{}}
            formatter={(v: number) => [v.toLocaleString(), "Logs"]}
          />
          <Area
            type="monotone"
            dataKey="logs"
            stroke="#2F7D4A"
            strokeWidth={2}
            fill="url(#logArea)"
            isAnimationActive
            animationDuration={1200}
          />
        </AreaChart>
      </ResponsiveContainer>
    </div>
  );
}
