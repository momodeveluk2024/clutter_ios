import { NextResponse } from "next/server";
import { ADMIN_ACCESS_COOKIE, ADMIN_REFRESH_COOKIE, rawApi } from "@/lib/api";

export async function POST(request: Request) {
  const body = await request.json().catch(() => null);
  const email = typeof body?.email === "string" ? body.email : "";
  const password = typeof body?.password === "string" ? body.password : "";

  const backend = await rawApi.login(email, password);
  const payload = await backend.json().catch(() => null);
  if (!backend.ok) {
    return NextResponse.json(
      { error: payload?.error ?? "Could not sign in" },
      { status: backend.status },
    );
  }

  const response = NextResponse.json({ user: payload.user });
  const secure = process.env.NODE_ENV === "production";
  response.cookies.set(ADMIN_ACCESS_COOKIE, payload.access, {
    httpOnly: true,
    sameSite: "lax",
    secure,
    path: "/",
    maxAge: 60 * 15,
  });
  response.cookies.set(ADMIN_REFRESH_COOKIE, payload.refresh, {
    httpOnly: true,
    sameSite: "lax",
    secure,
    path: "/",
    maxAge: 60 * 60 * 24 * 30,
  });
  return response;
}
