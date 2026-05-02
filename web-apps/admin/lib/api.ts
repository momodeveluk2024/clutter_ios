import { cookies } from "next/headers";
import { mock, type Food, type Nutrient, type User, type MealLog, type ReminderTemplate, type Overview } from "./mock";
import { ADMIN_ACCESS_COOKIE, ADMIN_REFRESH_COOKIE } from "./auth-cookies";

const BASE = process.env.NEXT_PUBLIC_API_URL ?? "http://localhost:8080/v1";
const ALLOW_MOCKS = process.env.NEXT_PUBLIC_ALLOW_MOCKS === "true";
export { ADMIN_ACCESS_COOKIE, ADMIN_REFRESH_COOKIE };

export class ApiError extends Error {
  constructor(message: string, readonly status?: number) {
    super(message);
  }
}

export type AiEstimateItem = {
  id: string;
  name: string;
  matchedFoodId?: string;
  quantityG: number;
  caloriesKcal: number;
  proteinG: number;
  carbsG: number;
  fatG: number;
  confidence: number;
  source: string;
};

export type AiEstimate = {
  id: string;
  userId?: string;
  userEmail?: string;
  imageUrl?: string;
  provider: string;
  model: string;
  status: string;
  confidence: number;
  mealType: string;
  loggedOn: string;
  locale: string;
  unitSystem: string;
  question?: string;
  questions: string[];
  warnings: string[];
  acceptedLogId?: string;
  reviewedStatus?: string;
  reviewNotes?: string;
  items: AiEstimateItem[];
  createdAt: string;
  updatedAt: string;
};

export type AiUsageSummary = {
  requests: number;
  failures: number;
  averageLatencyMs: number;
  inputTokens: number;
  outputTokens: number;
  models: {
    model: string;
    provider: string;
    requests: number;
    failures: number;
  }[];
};

export async function backendFetch(path: string, init: RequestInit = {}): Promise<Response> {
  const cookieStore = await cookies();
  const access = cookieStore.get(ADMIN_ACCESS_COOKIE)?.value;
  const headers = new Headers(init.headers);
  headers.set("Accept", "application/json");
  if (!(init.body instanceof FormData)) {
    headers.set("Content-Type", headers.get("Content-Type") ?? "application/json");
  }
  if (access) {
    headers.set("Authorization", `Bearer ${access}`);
  }
  return fetch(`${BASE}${path}`, {
    ...init,
    headers,
    cache: "no-store",
  });
}

async function fetchJson(path: string, init: RequestInit = {}): Promise<unknown> {
  const res = await backendFetch(path, init);
  if (!res.ok) {
    let message = `Backend request failed (${res.status})`;
    try {
      const body = await res.json();
      if (body && typeof body === "object" && "error" in body) {
        message = String((body as { error: unknown }).error);
      }
    } catch {
      // Keep status-based message.
    }
    throw new ApiError(message, res.status);
  }
  if (res.status === 204) return null;
  return res.json();
}

function logFallback(path: string) {
  if (typeof window !== "undefined") {
    // eslint-disable-next-line no-console
    console.info(`[api] mock fallback for ${path}`);
  }
}

async function tryGet<T>(path: string, pick: (raw: unknown) => T | undefined, fallback: T): Promise<T> {
  try {
    const raw = await fetchJson(path);
    const got = pick(raw);
    if (got === undefined) throw new ApiError("Unexpected backend response shape");
    return got;
  } catch (error) {
    if (ALLOW_MOCKS) {
      logFallback(path);
      return fallback;
    }
    throw error;
  }
}

const asArray = <T>(v: unknown): T[] | undefined => (Array.isArray(v) ? (v as T[]) : undefined);

function normalizeFood(raw: Record<string, unknown>): Food {
  const nutrients = Array.isArray(raw.nutrients) ? raw.nutrients : [];
  return {
    id: String(raw.id ?? ""),
    name: String(raw.name ?? "(unnamed)"),
    brand: (raw.brand as string | undefined) ?? undefined,
    category: String(raw.category ?? "general"),
    servingSizeG: Number(raw.servingSizeG ?? raw.serving_size_g ?? 100),
    imageUrl: (raw.imageUrl as string | undefined) ?? (raw.image_url as string | undefined) ?? undefined,
    barcode: (raw.barcode as string | undefined) ?? undefined,
    source: normalizeSource(raw.source),
    verified: Boolean(raw.verified),
    updatedAt: String(raw.updatedAt ?? raw.updated_at ?? raw.created_at ?? new Date().toISOString()),
    nutrients: nutrients.map((n) => {
      if (typeof n === "string") {
        return { code: n as Food["nutrients"][number]["code"], name: n, amount: 0, unit: "" };
      }
      const nn = n as Record<string, unknown>;
      return {
        code: (nn.code as Food["nutrients"][number]["code"]) ?? "C",
        name: String(nn.name ?? nn.code ?? ""),
        amount: Number(nn.amount ?? nn.amount_per_100g ?? 0),
        unit: String(nn.unit ?? ""),
      };
    }),
  };
}

function normalizeSource(value: unknown): Food["source"] {
  if (value === "seed" || value === "manual" || value === "user_submitted") return value;
  if (value === "user") return "user_submitted";
  if (value === "ai_estimate") return "user_submitted";
  return "manual";
}

function normalizeStringList(value: unknown): string[] {
  return Array.isArray(value) ? value.map((item) => String(item)) : [];
}

function normalizeAiEstimateItem(raw: Record<string, unknown>): AiEstimateItem {
  return {
    id: String(raw.id ?? ""),
    name: String(raw.name ?? "Unknown item"),
    matchedFoodId: (raw.matchedFoodId as string | undefined) ?? (raw.matched_food_id as string | undefined) ?? undefined,
    quantityG: Number(raw.quantityG ?? raw.quantity_g ?? 0),
    caloriesKcal: Number(raw.caloriesKcal ?? raw.calories_kcal ?? 0),
    proteinG: Number(raw.proteinG ?? raw.protein_g ?? 0),
    carbsG: Number(raw.carbsG ?? raw.carbs_g ?? 0),
    fatG: Number(raw.fatG ?? raw.fat_g ?? 0),
    confidence: Number(raw.confidence ?? 0),
    source: String(raw.source ?? "ai_estimate"),
  };
}

function normalizeAiEstimate(raw: Record<string, unknown>): AiEstimate {
  const items = Array.isArray(raw.items) ? raw.items : [];
  return {
    id: String(raw.id ?? raw.estimate_id ?? ""),
    userId: (raw.userId as string | undefined) ?? (raw.user_id as string | undefined) ?? undefined,
    userEmail: (raw.userEmail as string | undefined) ?? (raw.user_email as string | undefined) ?? undefined,
    imageUrl: (raw.imageUrl as string | undefined) ?? (raw.image_url as string | undefined) ?? undefined,
    provider: String(raw.provider ?? ""),
    model: String(raw.model ?? ""),
    status: String(raw.status ?? "pending"),
    confidence: Number(raw.confidence ?? 0),
    mealType: String(raw.mealType ?? raw.meal_type ?? "meal"),
    loggedOn: String(raw.loggedOn ?? raw.logged_on ?? ""),
    locale: String(raw.locale ?? "en"),
    unitSystem: String(raw.unitSystem ?? raw.unit_system ?? "metric"),
    question: (raw.question as string | undefined) ?? undefined,
    questions: normalizeStringList(raw.questions),
    warnings: normalizeStringList(raw.warnings),
    acceptedLogId: (raw.acceptedLogId as string | undefined) ?? (raw.accepted_log_id as string | undefined) ?? undefined,
    reviewedStatus: (raw.reviewedStatus as string | undefined) ?? (raw.reviewed_status as string | undefined) ?? undefined,
    reviewNotes: (raw.reviewNotes as string | undefined) ?? (raw.review_notes as string | undefined) ?? undefined,
    items: items.map((item) => normalizeAiEstimateItem(item as Record<string, unknown>)),
    createdAt: String(raw.createdAt ?? raw.created_at ?? new Date().toISOString()),
    updatedAt: String(raw.updatedAt ?? raw.updated_at ?? new Date().toISOString()),
  };
}

const pickAiEstimates = (raw: unknown): AiEstimate[] | undefined => {
  const arr = pickEnvelopeArray<unknown>("estimates")(raw);
  return arr?.map((r) => normalizeAiEstimate(r as Record<string, unknown>));
};

const pickAiUsage = (raw: unknown): AiUsageSummary | undefined => {
  if (!raw || typeof raw !== "object") return undefined;
  const obj = raw as Record<string, unknown>;
  const models = Array.isArray(obj.models) ? obj.models : [];
  return {
    requests: Number(obj.requests ?? 0),
    failures: Number(obj.failures ?? 0),
    averageLatencyMs: Number(obj.averageLatencyMs ?? obj.average_latency_ms ?? 0),
    inputTokens: Number(obj.inputTokens ?? obj.input_tokens ?? 0),
    outputTokens: Number(obj.outputTokens ?? obj.output_tokens ?? 0),
    models: models.map((model) => {
      const m = model as Record<string, unknown>;
      return {
        model: String(m.model ?? ""),
        provider: String(m.provider ?? ""),
        requests: Number(m.requests ?? 0),
        failures: Number(m.failures ?? 0),
      };
    }),
  };
};

function pickEnvelopeArray<T>(key: string) {
  return (raw: unknown): T[] | undefined => {
    if (Array.isArray(raw)) return raw as T[];
    if (raw && typeof raw === "object" && key in raw && Array.isArray((raw as Record<string, unknown>)[key])) {
      return (raw as Record<string, unknown>)[key] as T[];
    }
    return undefined;
  };
}

const pickFoods = (raw: unknown): Food[] | undefined => {
  const arr = pickEnvelopeArray<unknown>("foods")(raw);
  return arr?.map((r) => normalizeFood(r as Record<string, unknown>));
};

const pickFood = (raw: unknown): Food | undefined => {
  if (!raw || typeof raw !== "object") return undefined;
  const obj = "food" in raw ? (raw as { food: unknown }).food : raw;
  if (!obj || typeof obj !== "object") return undefined;
  return normalizeFood(obj as Record<string, unknown>);
};

const pickOverview = (raw: unknown): Overview | undefined => {
  if (raw && typeof raw === "object" && "kpis" in raw) return raw as Overview;
  return undefined;
};

export const api = {
  listFoods: (params: { q?: string; category?: string; verified?: string } = {}) => {
    const query = new URLSearchParams({ limit: "100" });
    if (params.q) query.set("q", params.q);
    if (params.category) query.set("category", params.category);
    if (params.verified) query.set("verified", params.verified);
    return tryGet<Food[]>(`/admin/foods?${query}`, pickFoods, mock.foods);
  },
  getFood: (id: string) => tryGet<Food>(`/admin/foods?limit=100`, (raw) => pickFoods(raw)?.find((f) => f.id === id), mock.foods.find((f) => f.id === id) ?? mock.foods[0])
    .then(async (summary) => {
      const detail = await tryGet<Food>(`/foods/${id}`, pickFood, summary);
      return { ...summary, ...detail };
    }),
  listNutrients: () => tryGet<Nutrient[]>("/admin/nutrients", pickEnvelopeArray<Nutrient>("nutrients"), mock.nutrients),
  listMealLogs: (params: { from?: string; to?: string } = {}) => {
    const query = new URLSearchParams({ limit: "100" });
    if (params.from) query.set("from", params.from);
    if (params.to) query.set("to", params.to);
    return tryGet<MealLog[]>(`/admin/logs?${query}`, pickEnvelopeArray<MealLog>("logs"), mock.mealLogs);
  },
  listUsers: (status = "") => tryGet<User[]>(`/admin/users?limit=100${status ? `&status=${encodeURIComponent(status)}` : ""}`, pickEnvelopeArray<User>("users"), mock.users),
  getUser: (id: string) => tryGet<User>(`/admin/users/${id}`, (raw) => (raw && typeof raw === "object" && "id" in raw ? (raw as User) : undefined), mock.users.find((u) => u.id === id) ?? mock.users[0]),
  listReminderTemplates: () => tryGet<ReminderTemplate[]>("/admin/reminder-templates", (raw) => {
    const reminders = pickEnvelopeArray<Record<string, unknown>>("templates")(raw) ?? pickEnvelopeArray<Record<string, unknown>>("reminders")(raw);
    return reminders?.map((r) => ({
      id: String(r.id ?? ""),
      title: String(r.title ?? ""),
      body: String(r.body ?? "Reminder"),
      trigger: String(r.trigger ?? r.remindAt ?? ""),
      audience: String(r.audience ?? r.userEmail ?? "User"),
      sent7d: Number(r.sent7d ?? 0),
      active: Boolean(r.active),
      updatedAt: String(r.updatedAt ?? ""),
    }));
  }, mock.reminderTemplates),
  overview: (range = "week") => tryGet<Overview>(`/admin/overview?range=${encodeURIComponent(range)}`, pickOverview, mock.overview),
  listAiEstimates: (params: { status?: string } = {}) => {
    const query = new URLSearchParams({ limit: "100" });
    if (params.status) query.set("status", params.status);
    return tryGet<AiEstimate[]>(`/admin/ai/estimates?${query}`, pickAiEstimates, []);
  },
  aiUsage: () => tryGet<AiUsageSummary>("/admin/ai/usage", pickAiUsage, {
    requests: 0,
    failures: 0,
    averageLatencyMs: 0,
    inputTokens: 0,
    outputTokens: 0,
    models: [],
  }),
};

export async function mutateJson<T = unknown>(path: string, body: unknown, method = "POST"): Promise<T> {
  return fetchJson(path, { method, body: JSON.stringify(body) }) as Promise<T>;
}

export async function mutateFormData<T = unknown>(path: string, formData: FormData): Promise<T> {
  return fetchJson(path, { method: "POST", body: formData }) as Promise<T>;
}

export async function deleteResource(path: string): Promise<void> {
  await fetchJson(path, { method: "DELETE" });
}

export function toCsv(rows: Array<Record<string, unknown>>, headers: string[]): string {
  const escape = (value: unknown) => {
    const raw = value == null ? "" : String(value);
    return /[",\n]/.test(raw) ? `"${raw.replaceAll('"', '""')}"` : raw;
  };
  return [headers.join(","), ...rows.map((row) => headers.map((h) => escape(row[h])).join(","))].join("\n");
}

export async function exportFoodsCsv() {
  const foods = await api.listFoods();
  return toCsv(foods as unknown as Array<Record<string, unknown>>, ["id", "name", "brand", "category", "servingSizeG", "source", "verified", "imageUrl"]);
}

export async function exportUsersCsv() {
  const users = await api.listUsers();
  return toCsv(users as unknown as Array<Record<string, unknown>>, ["id", "email", "displayName", "role", "status", "logs30d", "lastActive", "joined"]);
}

export async function exportMealLogsCsv() {
  const logs = await api.listMealLogs();
  return toCsv(logs as unknown as Array<Record<string, unknown>>, ["id", "userId", "userEmail", "loggedAt", "meal", "items"]);
}

export async function exportNutrientsCsv() {
  const nutrients = await api.listNutrients();
  return toCsv(nutrients as unknown as Array<Record<string, unknown>>, ["id", "code", "name", "unit", "group", "driAdult", "foodCount"]);
}

export async function exportReminderTemplatesCsv() {
  const templates = await api.listReminderTemplates();
  return toCsv(templates as unknown as Array<Record<string, unknown>>, ["id", "title", "body", "trigger", "audience", "sent7d", "active"]);
}

export const rawApi = {
  login: (email: string, password: string) => fetch(`${BASE}/admin/auth/login`, {
    method: "POST",
    headers: { "Content-Type": "application/json", Accept: "application/json" },
    body: JSON.stringify({ email, password }),
    cache: "no-store",
  }),
  logout: () => backendFetch("/auth/logout", { method: "POST" }),
};
