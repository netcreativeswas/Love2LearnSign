import type { ReactNode } from "react";

type PageShellProps = {
  title: string;
  lede?: string;
  children: ReactNode;
};

export function PageShell({ title, lede, children }: PageShellProps) {
  return (
    <main className="mx-auto w-full max-w-5xl px-4 py-10 sm:py-14">
      <header className="mb-8 space-y-3">
        <h1 className="text-balance text-3xl font-semibold tracking-tight sm:text-4xl">
          {title}
        </h1>
        {lede ? (
          <p className="max-w-prose text-base leading-7 text-muted-foreground sm:text-lg">
            {lede}
          </p>
        ) : null}
      </header>

      {children}
    </main>
  );
}


