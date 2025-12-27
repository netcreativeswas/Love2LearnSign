import type { ReactNode } from "react";

type SectionCardProps = {
  title: string;
  children: ReactNode;
};

export function SectionCard({ title, children }: SectionCardProps) {
  return (
    <section className="rounded-3xl border border-border bg-surface p-6 shadow-sm sm:p-8">
      <h2 className="text-xl font-semibold tracking-tight">{title}</h2>
      <div className="mt-4 space-y-3 text-sm leading-7 text-foreground/90">
        {children}
      </div>
    </section>
  );
}


