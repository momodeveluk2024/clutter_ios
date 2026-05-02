"use client";

import { Suspense, useState } from "react";
import { useSearchParams } from "next/navigation";
import { motion } from "motion/react";
import Link from "next/link";
import { Button } from "@/components/ui/Button";
import { AlertTriangle } from "lucide-react";

export default function LoginPage() {
  return (
    <Suspense fallback={null}>
      <LoginForm />
    </Suspense>
  );
}

function LoginForm() {
  const searchParams = useSearchParams();
  const [email, setEmail] = useState("jane@nv.app");
  const [password, setPassword] = useState("");
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const submit = async (e: React.FormEvent) => {
    e.preventDefault();
    setSubmitting(true);
    setError(null);

    const response = await fetch("/api/admin/login", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ email, password }),
    });

    if (!response.ok) {
      const body = await response.json().catch(() => null);
      setError(body?.error ?? "Could not sign in.");
      setSubmitting(false);
      return;
    }

    window.location.assign(searchParams.get("next") ?? "/");
  };

  return (
    <div className="login-page min-h-screen grid grid-cols-1 md:grid-cols-2">
      <section className="bg-[var(--color-surface)] p-12 md:p-16 flex flex-col">
        <Link href="/" className="flex items-center gap-2.5">
          <span className="grid place-items-center w-8 h-8 rounded-[10px] bg-[var(--color-accent)] text-white font-extrabold text-sm">
            NV
          </span>
          <span className="font-semibold tracking-tight">NV Admin</span>
        </Link>

        <motion.div
          initial={{ opacity: 0, y: 12 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.6, ease: [0.2, 0.65, 0.3, 0.9] }}
          className="my-auto max-w-md w-full"
        >
          <p className="eyebrow">Welcome back</p>
          <h1 className="text-[40px] font-bold tracking-tight leading-[1.05] mt-3 mb-2">
            Sign in to your<br />admin console
          </h1>
          <p className="text-[var(--color-text-muted)] text-[15px] leading-relaxed mb-8">
            Manage the food database, monitor user activity and tune notification policies.
          </p>

          <div className="flex items-start gap-2.5 px-3.5 py-3 rounded-xl border border-[#F0D2B0] bg-[var(--color-warn-soft)] text-[#8A4B20] text-[12px] mb-6">
            <AlertTriangle size={14} className="mt-0.5 shrink-0" />
            <p>This console is for admin accounts only. User logins happen in the mobile app.</p>
          </div>

          <form onSubmit={submit} className="space-y-4">
            {error && (
              <div className="px-3.5 py-3 rounded-xl border border-[#F0D2D2] bg-[#FFF2F2] text-[var(--color-err)] text-[12px]">
                {error}
              </div>
            )}
            <div>
              <label className="block text-[12px] font-semibold mb-1.5">Email</label>
              <input
                type="email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                className="w-full h-10 px-3.5 bg-white border border-[var(--color-border)] rounded-[12px] text-[14px] focus:outline-none focus:border-[var(--color-accent)] focus:ring-2 focus:ring-[var(--color-accent-soft)]"
              />
            </div>
            <div>
              <label className="block text-[12px] font-semibold mb-1.5">Password</label>
              <input
                type="password"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                className="w-full h-10 px-3.5 bg-white border border-[var(--color-border)] rounded-[12px] text-[14px] focus:outline-none focus:border-[var(--color-accent)] focus:ring-2 focus:ring-[var(--color-accent-soft)]"
              />
            </div>

            <div className="flex items-center justify-between text-[12px] py-2">
              <label className="inline-flex items-center gap-2 text-[var(--color-text-muted)]">
                <input type="checkbox" defaultChecked className="accent-[var(--color-accent)]" />
                Remember this device
              </label>
              <span className="text-[var(--color-text-muted)]">Password reset runs from the mobile auth flow</span>
            </div>

            <Button type="submit" size="md" className="w-full" disabled={submitting}>
              {submitting ? "Signing in..." : "Sign in"}
            </Button>
          </form>
        </motion.div>

        <div className="mt-auto pt-8 flex gap-5 text-[11px] text-[var(--color-text-muted)]">
          <Link href="http://localhost:3001" className="hover:text-[var(--color-text)]">Back to nv.app</Link>
          <span>Privacy</span>
          <span>Terms</span>
          <span>Status</span>
        </div>
      </section>

      <aside
        className="hidden md:flex relative p-16 flex-col justify-between text-[#F1F3EE] overflow-hidden"
        style={{ background: "linear-gradient(160deg,#1E5A34 0%,#2F7D4A 60%,#3B9159 100%)" }}
      >
        <motion.div
          initial={{ opacity: 0 }}
          animate={{ opacity: 0.4 }}
          transition={{ duration: 1.4 }}
          className="absolute -top-32 -right-40 w-[520px] h-[520px] rounded-full pointer-events-none"
          style={{ background: "radial-gradient(circle, rgba(255,255,255,0.16) 0%, transparent 70%)" }}
        />
        <p className="eyebrow !text-[#B6E0C2]">NV Admin · live</p>
        <div className="relative">
          <p className="text-[28px] font-semibold tracking-tight leading-[1.2] max-w-md">
            The database is the product. <em className="not-italic text-[#B6E0C2]">This is where it lives.</em>
          </p>
          <p className="text-[#C8DBCD] text-[13px] mt-3">Connected to the Go backend</p>
        </div>
        <div className="grid grid-cols-3 gap-6 pt-8 border-t border-white/15 relative">
          <Stat n="Live" label="Backend" />
          <Stat n="Role" label="Admin auth" />
          <Stat n="Real" label="Data" />
        </div>
      </aside>
    </div>
  );
}

function Stat({ n, label }: { n: string; label: string }) {
  return (
    <div>
      <strong className="block text-2xl tracking-tight">{n}</strong>
      <span className="text-[12px] text-[#C8DBCD]">{label}</span>
    </div>
  );
}
