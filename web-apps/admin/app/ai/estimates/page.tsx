import { revalidatePath } from "next/cache";
import type { ReactNode } from "react";
import { api, mutateJson, type AiEstimate } from "@/lib/api";
import { PageHeader } from "@/components/ui/PageHeader";
import { Chip } from "@/components/ui/Chip";
import { Table, THead, TH, TBody, TRow, TD } from "@/components/ui/Table";
import { fmtRelative } from "@/lib/utils";
import { Bot, CheckCircle2, Image as ImageIcon, XCircle } from "lucide-react";

export const dynamic = "force-dynamic";

async function reviewEstimate(formData: FormData) {
  "use server";

  const id = String(formData.get("id") ?? "");
  const status = String(formData.get("status") ?? "");
  const notes = String(formData.get("notes") ?? "");
  if (!id || !status) return;

  await mutateJson(`/admin/ai/estimates/${id}/review`, { status, notes }, "PATCH");
  revalidatePath("/ai/estimates");
}

export default async function AiEstimatesPage({
  searchParams,
}: {
  searchParams: Promise<{ status?: string }>;
}) {
  const filters = await searchParams;
  const estimates = await api.listAiEstimates({ status: filters.status });
  const needingReview = estimates.filter((estimate) => estimate.status === "needs_review").length;
  const accepted = estimates.filter((estimate) => estimate.status === "accepted").length;
  const failed = estimates.filter((estimate) => estimate.status === "failed").length;

  return (
    <div className="p-8">
      <PageHeader
        title="AI estimates"
        sub={`${estimates.length} estimates - ${needingReview} need review`}
        actions={
          <div className="inline-flex items-center gap-2 text-[12px] text-[var(--color-text-muted)]">
            <Bot size={14} />
            <span>Gemini primary, Claude fallback</span>
          </div>
        }
      />

      <div className="grid grid-cols-1 md:grid-cols-3 gap-3 mb-5">
        <SummaryPill icon={<ImageIcon size={15} />} label="Needs review" value={needingReview} />
        <SummaryPill icon={<CheckCircle2 size={15} />} label="Accepted" value={accepted} />
        <SummaryPill icon={<XCircle size={15} />} label="Failed" value={failed} />
      </div>

      <form className="rounded-t-[18px] border border-b-0 border-[var(--color-border)] bg-[var(--color-surface)] p-3 flex gap-2 items-center" action="/ai/estimates">
        <select
          name="status"
          defaultValue={filters.status ?? ""}
          className="h-9 px-3 bg-white border border-[var(--color-border)] rounded-[10px] text-[13px]"
        >
          <option value="">All statuses</option>
          <option value="pending">Pending</option>
          <option value="needs_review">Needs review</option>
          <option value="accepted">Accepted</option>
          <option value="failed">Failed</option>
        </select>
        <button className="h-9 px-3 rounded-[10px] border border-[var(--color-border)] text-[13px] font-semibold hover:bg-[var(--color-surface-muted)]" type="submit">
          Apply
        </button>
      </form>

      <Table className="rounded-t-none border-t-0">
        <THead>
          <TH>Estimate</TH>
          <TH>User</TH>
          <TH>Model</TH>
          <TH>Items</TH>
          <TH>Confidence</TH>
          <TH>Status</TH>
          <TH>Review</TH>
        </THead>
        <TBody>
          {estimates.map((estimate, i) => (
            <TRow key={estimate.id} index={i}>
              <TD>
                <div className="flex items-center gap-3">
                  <PhotoThumb estimate={estimate} />
                  <div className="min-w-0">
                    <p className="font-semibold text-[var(--color-text)] capitalize">{estimate.mealType}</p>
                    <p className="text-[11px] text-[var(--color-text-muted)]">{estimate.loggedOn} - {fmtRelative(estimate.createdAt)}</p>
                    {estimate.question && (
                      <p className="text-[11px] text-[var(--color-text-muted)] truncate max-w-[220px] mt-0.5">{estimate.question}</p>
                    )}
                  </div>
                </div>
              </TD>
              <TD>
                <p className="font-medium">{estimate.userEmail ?? "Unknown user"}</p>
                <p className="text-[11px] text-[var(--color-text-muted)] truncate max-w-[180px]">{estimate.userId}</p>
              </TD>
              <TD>
                <p className="font-medium">{estimate.model || "development"}</p>
                <p className="text-[11px] text-[var(--color-text-muted)] capitalize">{estimate.provider || "local"}</p>
              </TD>
              <TD>
                <div className="space-y-1">
                  {estimate.items.slice(0, 3).map((item) => (
                    <p key={item.id} className="text-[12px] text-[var(--color-text-muted)]">
                      <span className="font-medium text-[var(--color-text)]">{item.name}</span> - {Math.round(item.quantityG)} g
                    </p>
                  ))}
                  {estimate.items.length > 3 && (
                    <p className="text-[11px] text-[var(--color-text-muted)]">+{estimate.items.length - 3} more</p>
                  )}
                </div>
              </TD>
              <TD>
                <span className="tabular font-semibold">{Math.round(estimate.confidence * 100)}%</span>
              </TD>
              <TD>
                <Chip variant={statusVariant(estimate.status)} dot>{statusLabel(estimate.status)}</Chip>
                {estimate.reviewedStatus && (
                  <p className="text-[11px] text-[var(--color-text-muted)] mt-1">Review: {statusLabel(estimate.reviewedStatus)}</p>
                )}
              </TD>
              <TD>
                <form action={reviewEstimate} className="flex items-center gap-2">
                  <input type="hidden" name="id" value={estimate.id} />
                  <select
                    name="status"
                    defaultValue={estimate.reviewedStatus ?? "approved"}
                    className="h-8 px-2 bg-white border border-[var(--color-border)] rounded-[8px] text-[12px]"
                  >
                    <option value="approved">Approve</option>
                    <option value="bad_estimate">Bad estimate</option>
                    <option value="needs_catalog_fix">Catalog fix</option>
                  </select>
                  <input
                    name="notes"
                    defaultValue={estimate.reviewNotes ?? ""}
                    placeholder="Notes"
                    className="h-8 w-28 px-2 bg-white border border-[var(--color-border)] rounded-[8px] text-[12px]"
                  />
                  <button className="h-8 px-2 rounded-[8px] bg-[var(--color-accent)] text-white text-[12px] font-semibold" type="submit">
                    Save
                  </button>
                </form>
              </TD>
            </TRow>
          ))}
        </TBody>
      </Table>
    </div>
  );
}

function SummaryPill({ icon, label, value }: { icon: ReactNode; label: string; value: number }) {
  return (
    <div className="rounded-[16px] border border-[var(--color-border)] bg-[var(--color-surface)] p-4 flex items-center gap-3">
      <span className="w-9 h-9 rounded-full bg-[var(--color-accent-soft)] text-[var(--color-accent-deep)] grid place-items-center">{icon}</span>
      <div>
        <p className="eyebrow">{label}</p>
        <p className="text-[22px] font-bold tabular leading-none mt-1">{value}</p>
      </div>
    </div>
  );
}

function PhotoThumb({ estimate }: { estimate: AiEstimate }) {
  if (!estimate.imageUrl) {
    return (
      <span className="w-12 h-12 rounded-[12px] bg-[var(--color-surface-muted)] grid place-items-center text-[var(--color-text-muted)]">
        <ImageIcon size={16} />
      </span>
    );
  }
  return (
    // eslint-disable-next-line @next/next/no-img-element
    <img src={estimate.imageUrl} alt="" className="w-12 h-12 rounded-[12px] object-cover border border-[var(--color-border)]" />
  );
}

function statusVariant(status: string): "default" | "accent" | "warn" | "err" | "muted" {
  if (status === "accepted" || status === "approved") return "accent";
  if (status === "failed" || status === "bad_estimate") return "err";
  if (status === "needs_review" || status === "needs_catalog_fix") return "warn";
  if (status === "pending") return "muted";
  return "default";
}

function statusLabel(status: string) {
  return status.replaceAll("_", " ");
}
