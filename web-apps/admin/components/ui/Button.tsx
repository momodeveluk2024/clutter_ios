import { forwardRef, type ReactNode, type ButtonHTMLAttributes, type AnchorHTMLAttributes } from "react";
import { cn } from "@/lib/utils";

type Variant = "primary" | "ghost" | "danger";
type Size = "xs" | "sm" | "md";

const base =
  "inline-flex items-center justify-center gap-2 font-semibold whitespace-nowrap rounded-full transition-colors";

const variants: Record<Variant, string> = {
  primary: "bg-[var(--color-accent)] text-white hover:bg-[var(--color-accent-deep)]",
  ghost:   "bg-transparent text-[var(--color-text)] border border-[var(--color-border)] hover:bg-[var(--color-surface-muted)]",
  danger:  "bg-transparent text-[var(--color-err)] border border-[var(--color-border)] hover:bg-[var(--color-err)] hover:text-white hover:border-[var(--color-err)]",
};

const sizes: Record<Size, string> = {
  xs: "h-7  px-3 text-[11px]",
  sm: "h-8  px-3.5 text-[12px]",
  md: "h-10 px-5 text-[13px]",
};

type Common = { variant?: Variant; size?: Size; className?: string; children: ReactNode };
type AsButton = Common & { href?: undefined } & ButtonHTMLAttributes<HTMLButtonElement>;
type AsAnchor = Common & { href: string } & AnchorHTMLAttributes<HTMLAnchorElement>;

export const Button = forwardRef<HTMLButtonElement | HTMLAnchorElement, AsButton | AsAnchor>(
  function Button({ variant = "primary", size = "sm", className, children, ...props }, ref) {
    const cls = cn(base, variants[variant], sizes[size], className);
    if ("href" in props && props.href) {
      const { href, ...rest } = props as AsAnchor;
      return (
        <a ref={ref as React.Ref<HTMLAnchorElement>} href={href} className={cls} {...rest}>
          {children}
        </a>
      );
    }
    return (
      <button
        ref={ref as React.Ref<HTMLButtonElement>}
        className={cls}
        {...(props as ButtonHTMLAttributes<HTMLButtonElement>)}
      >
        {children}
      </button>
    );
  },
);
