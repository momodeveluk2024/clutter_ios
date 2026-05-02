import { forwardRef, type ReactNode, type ButtonHTMLAttributes, type AnchorHTMLAttributes } from "react";
import { cn } from "@/lib/utils";

type Variant = "primary" | "ghost" | "dark";
type Size = "sm" | "md" | "lg";

const base =
  "inline-flex items-center justify-center gap-2 font-semibold whitespace-nowrap rounded-full transition-[background,color,border-color,transform] duration-200 will-change-transform";

const variants: Record<Variant, string> = {
  primary:
    "bg-[var(--color-accent)] text-white hover:bg-[var(--color-accent-deep)]",
  ghost:
    "bg-transparent text-[var(--color-text)] border border-[var(--color-border)] hover:bg-[var(--color-surface-muted)]",
  dark: "bg-[var(--color-text)] text-white hover:bg-black",
};

const sizes: Record<Size, string> = {
  sm: "h-9 px-4 text-[12px]",
  md: "h-12 px-6 text-[14px]",
  lg: "h-14 px-8 text-[15px]",
};

type Common = { variant?: Variant; size?: Size; className?: string; children: ReactNode };

type AsButton = Common & { href?: undefined } & ButtonHTMLAttributes<HTMLButtonElement>;
type AsAnchor = Common & { href: string } & AnchorHTMLAttributes<HTMLAnchorElement>;

export const Button = forwardRef<HTMLButtonElement | HTMLAnchorElement, AsButton | AsAnchor>(
  function Button({ variant = "primary", size = "md", className, children, ...props }, ref) {
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
