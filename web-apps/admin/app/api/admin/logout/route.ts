import { NextResponse } from "next/server";
import { ADMIN_ACCESS_COOKIE, ADMIN_REFRESH_COOKIE, rawApi } from "@/lib/api";

export async function POST() {
  await rawApi.logout().catch(() => null);
  const response = NextResponse.json({ ok: true });
  response.cookies.delete(ADMIN_ACCESS_COOKIE);
  response.cookies.delete(ADMIN_REFRESH_COOKIE);
  return response;
}
