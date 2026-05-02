import Image from "next/image";
import Link from "next/link";
import { photos } from "@/lib/images";

export function Footer() {
  const photographers = Array.from(new Set(photos.map((p) => p.photographer))).slice(0, 6);

  return (
    <footer className="border-t border-[var(--color-border)] bg-[var(--color-bg)]">
      <div className="mx-auto max-w-7xl px-6 py-16">
        <div className="grid grid-cols-2 md:grid-cols-5 gap-12">
          <div className="col-span-2">
            <Link href="/" className="flex items-center gap-2.5 mb-4">
              <span className="relative w-9 h-9 grid place-items-center">
                <Image src="/logo.png" alt="Nutrimate logo" width={36} height={36} className="object-contain" />
              </span>
              <span className="font-semibold tracking-tight">Nutrimate</span>
            </Link>
            <p className="text-sm text-[var(--color-text-muted)] max-w-sm leading-relaxed">
              A nutrition tracker built around vitamins and minerals — not just calories.
              Built on USDA dietary references.
            </p>
          </div>

          <FootCol title="Product">
            <FootLink href="/features">Features</FootLink>
            <FootLink href="/about">About</FootLink>
            <FootLink href="/download">Download</FootLink>
          </FootCol>

          <FootCol title="Company">
            <FootLink href="#">Press</FootLink>
            <FootLink href="#">Blog</FootLink>
            <FootLink href="#">Contact</FootLink>
          </FootCol>

          <FootCol title="Legal">
            <FootLink href="#">Privacy</FootLink>
            <FootLink href="#">Terms</FootLink>
            <FootLink href="#">Security</FootLink>
          </FootCol>
        </div>

        <div className="mt-16 pt-8 border-t border-[var(--color-border)] flex flex-col md:flex-row md:items-center md:justify-between gap-4 text-xs text-[var(--color-text-muted)]">
          <p>© 2026 Nutrimate. All rights reserved.</p>
          <p>
            Photography by {photographers.map((p, i) => (
              <span key={p}>
                <a
                  href={`https://unsplash.com/?utm_source=nv&utm_medium=referral`}
                  className="underline hover:text-[var(--color-text)]"
                  target="_blank"
                  rel="noopener noreferrer"
                >
                  {p}
                </a>
                {i < photographers.length - 1 ? ", " : ""}
              </span>
            ))} on Unsplash.
          </p>
        </div>
      </div>
    </footer>
  );
}

function FootCol({ title, children }: { title: string; children: React.ReactNode }) {
  return (
    <div>
      <h4 className="eyebrow mb-3">{title}</h4>
      <div className="flex flex-col gap-2">{children}</div>
    </div>
  );
}

function FootLink({ href, children }: { href: string; children: React.ReactNode }) {
  return (
    <Link
      href={href}
      className="text-sm text-[var(--color-text-muted)] hover:text-[var(--color-text)] transition-colors"
    >
      {children}
    </Link>
  );
}
