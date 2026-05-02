import { api } from "@/lib/api";
import { PageHeader } from "@/components/ui/PageHeader";
import { KpiCard } from "@/components/ui/KpiCard";
import { Chip } from "@/components/ui/Chip";
import { Table, THead, TH, TBody, TRow, TD } from "@/components/ui/Table";
import { Activity, Timer, Zap } from "lucide-react";

export const dynamic = "force-dynamic";

export default async function AiUsagePage() {
  const usage = await api.aiUsage();
  const failureRate = usage.requests === 0 ? 0 : (usage.failures / usage.requests) * 100;
  const totalTokens = usage.inputTokens + usage.outputTokens;

  return (
    <div className="p-8">
      <PageHeader
        title="AI usage"
        sub="Requests, failures, latency, and token volume"
        actions={
          <div className="inline-flex items-center gap-2 text-[12px] text-[var(--color-text-muted)]">
            <Activity size={14} />
            <span>Tracked from backend usage events</span>
          </div>
        }
      />

      <div className="grid grid-cols-1 md:grid-cols-4 gap-4 mb-6">
        <KpiCard label="Requests" value={usage.requests} helper="All AI operations" />
        <KpiCard label="Failure rate" value={failureRate} decimals={1} suffix="%" helper={`${usage.failures} failed`} />
        <KpiCard label="Avg latency" value={usage.averageLatencyMs} suffix="ms" helper="Provider round trip" />
        <KpiCard label="Tokens" value={totalTokens} helper={`${usage.inputTokens} input, ${usage.outputTokens} output`} />
      </div>

      <div className="rounded-t-[18px] border border-b-0 border-[var(--color-border)] bg-[var(--color-surface)] p-4 flex items-center gap-2">
        <Zap size={15} className="text-[var(--color-accent-deep)]" />
        <p className="text-[13px] font-semibold">Model totals</p>
      </div>
      <Table className="rounded-t-none border-t-0">
        <THead>
          <TH>Model</TH>
          <TH>Provider</TH>
          <TH>Requests</TH>
          <TH>Failures</TH>
          <TH>Reliability</TH>
        </THead>
        <TBody>
          {usage.models.map((model, i) => {
            const modelFailureRate = model.requests === 0 ? 0 : (model.failures / model.requests) * 100;
            return (
              <TRow key={`${model.provider}-${model.model}`} index={i}>
                <TD>
                  <p className="font-semibold">{model.model || "development"}</p>
                </TD>
                <TD className="capitalize text-[var(--color-text-muted)]">{model.provider || "local"}</TD>
                <TD className="tabular">{model.requests}</TD>
                <TD className="tabular">{model.failures}</TD>
                <TD>
                  <Chip variant={modelFailureRate > 5 ? "warn" : "accent"} dot>
                    {(100 - modelFailureRate).toFixed(1)}%
                  </Chip>
                </TD>
              </TRow>
            );
          })}
          {usage.models.length === 0 && (
            <TRow>
              <TD className="text-[var(--color-text-muted)]" colSpan={5}>
                No AI usage recorded yet.
              </TD>
            </TRow>
          )}
        </TBody>
      </Table>

      <div className="mt-4 rounded-[16px] border border-[var(--color-border)] bg-[var(--color-surface)] p-4 flex gap-3 text-[12px] text-[var(--color-text-muted)]">
        <Timer size={15} className="mt-0.5" />
        <p>
          Costs are estimated outside this page from provider pricing. This view keeps the audit trail focused on volume, reliability, and latency.
        </p>
      </div>
    </div>
  );
}
