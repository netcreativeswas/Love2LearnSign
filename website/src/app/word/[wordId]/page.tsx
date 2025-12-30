import WordViewerClient from "./WordViewerClient";
import { TranslationProvider } from "@/components/TranslationProvider";
import { defaultLocale, locales, type Locale } from "@/lib/i18n";

export default async function WordPage({
  params,
  searchParams,
}: {
  params: Promise<{ wordId: string }>;
  searchParams?: Promise<Record<string, string | string[] | undefined>>;
}) {
  const { wordId } = await params;
  const sp = (await searchParams) ?? {};

  const tenantParam = sp.tenant;
  const langParam = sp.lang;
  const uiParam = sp.ui ?? sp.locale;

  const tenantId = typeof tenantParam === "string" ? tenantParam : undefined;
  const signLangId = typeof langParam === "string" ? langParam : undefined;
  const uiLocale = typeof uiParam === "string" ? uiParam : undefined;
  const resolvedLocale = (uiLocale && locales.includes(uiLocale as Locale) ? uiLocale : defaultLocale) as Locale;

  return (
    <TranslationProvider locale={resolvedLocale}>
      <WordViewerClient
        wordId={wordId}
        tenantId={tenantId}
        signLangId={signLangId}
      />
    </TranslationProvider>
  );
}


