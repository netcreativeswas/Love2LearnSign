function safeJsonLdStringify(value: unknown): string {
  // Prevent `</script>` injection by escaping `<` (and a few other chars commonly escaped in JSON-in-HTML).
  // This is the standard hardening used by many JSON-LD examples.
  return JSON.stringify(value)
    .replace(/</g, "\\u003c")
    .replace(/>/g, "\\u003e")
    .replace(/&/g, "\\u0026")
    .replace(/\u2028/g, "\\u2028")
    .replace(/\u2029/g, "\\u2029");
}

interface StructuredDataProps {
  type:
  | "WebSite"
  | "Organization"
  | "MobileApplication"
  | "WebPage"
  | "BreadcrumbList"
  | "FAQPage";
  data: Record<string, unknown>;
}

export function StructuredData({ type, data }: StructuredDataProps) {
  const jsonLd = {
    "@context": "https://schema.org",
    "@type": type,
    ...data,
  };

  return (
    <script
      type="application/ld+json"
      dangerouslySetInnerHTML={{ __html: safeJsonLdStringify(jsonLd) }}
    />
  );
}

interface BreadcrumbItem {
  name: string;
  url: string;
}

export function BreadcrumbList({ items }: { items: BreadcrumbItem[] }) {
  const jsonLd = {
    "@context": "https://schema.org",
    "@type": "BreadcrumbList",
    itemListElement: items.map((item, index) => ({
      "@type": "ListItem",
      position: index + 1,
      name: item.name,
      item: item.url,
    })),
  };

  return (
    <script
      type="application/ld+json"
      dangerouslySetInnerHTML={{ __html: safeJsonLdStringify(jsonLd) }}
    />
  );
}

