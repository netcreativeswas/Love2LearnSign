import WordViewerClient from "./WordViewerClient";

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

  const tenantId = typeof tenantParam === "string" ? tenantParam : undefined;
  const signLangId = typeof langParam === "string" ? langParam : undefined;

  return (
    <WordViewerClient
      wordId={wordId}
      tenantId={tenantId}
      signLangId={signLangId}
    />
  );
}


