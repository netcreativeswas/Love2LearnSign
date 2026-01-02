"use client";

import { useState } from "react";
import { SiteFooter } from "@/components/SiteFooter";
import { SiteHeader } from "@/components/SiteHeader";
import { PageShell } from "@/components/PageShell";
import { SectionCard } from "@/components/SectionCard";
import Image from "next/image";
import { usePathname } from "next/navigation";
import { siteConfig } from "@/lib/site-config";
import { StructuredData, BreadcrumbList } from "@/components/StructuredData";
import { TranslationProvider, useTranslations } from "@/components/TranslationProvider";
import { Locale, getLocaleFromPath, getLocalizedPath, locales, defaultLocale } from "@/lib/i18n";

const STRIPE_CUSTOM_LINK = "https://donate.stripe.com/7sY9ANgkheEv2r40n38N208";
const STRIPE_LINKS: Record<number, string> = {
  2: "https://buy.stripe.com/9B63cpgkh2VNc1E1r78N200",
  5: "https://buy.stripe.com/bJe7sFc410NF8Ps6Lr8N201",
  10: "https://buy.stripe.com/14A8wJ2traof8Ps9XD8N202",
  20: "https://buy.stripe.com/7sYdR3c41dArc1Eb1H8N203",
};

const STRIPE_MONTHLY_LINKS: Record<number, string> = {
  2: "https://buy.stripe.com/7sY9ANgkheEv2r40n38N208",
  5: "https://buy.stripe.com/7sY9ANgkheEv2r40n38N208",
  10: "https://buy.stripe.com/7sY9ANgkheEv2r40n38N208",
  20: "https://buy.stripe.com/7sY9ANgkheEv2r40n38N208",
};

const PRESET_AMOUNTS = [2, 5, 10, 20] as const;

const PAYMENT_METHODS = ["buyMeACoffee", "kofi", "stripe", "bankTransfer"] as const;

type PaymentMethod = (typeof PAYMENT_METHODS)[number];

function DonatePageContent({ locale }: { locale: Locale }) {
  const { t } = useTranslations();
  
  const [selectedMethod, setSelectedMethod] = useState<PaymentMethod | null>(
    null
  );
  const [selectedPreset, setSelectedPreset] = useState<number | null>(null);
  const [isCustomSelected, setIsCustomSelected] = useState(false);
  const [customAmount, setCustomAmount] = useState("");
  const [isMonthly, setIsMonthly] = useState(false);
  const [bankTab, setBankTab] = useState<"euro" | "us">("euro");

  const handleDonate = () => {
    if (!selectedMethod) return;

    let url: string | null = null;

    if (selectedMethod === "buyMeACoffee") {
      url = "https://buymeacoffee.com/netcreative";
    } else if (selectedMethod === "kofi") {
      url = "https://ko-fi.com/netcreativejlc";
    } else if (selectedMethod === "stripe") {
      if (isCustomSelected) {
        url = STRIPE_CUSTOM_LINK;
      } else if (selectedPreset !== null) {
        if (isMonthly) {
          url = STRIPE_MONTHLY_LINKS[selectedPreset] || STRIPE_CUSTOM_LINK;
        } else {
          url = STRIPE_LINKS[selectedPreset] || STRIPE_CUSTOM_LINK;
        }
      }
    } else if (selectedMethod === "bankTransfer") {
      return;
    }

    if (url) {
      window.open(url, "_blank", "noopener,noreferrer");
    }
  };

  const copyToClipboard = async (text: string, label: string) => {
    try {
      await navigator.clipboard.writeText(text);
    } catch (err) {
      console.error("Failed to copy:", err);
    }
  };

  const requiresAmount =
    selectedMethod === "stripe" && !isCustomSelected && selectedPreset === null;

  return (
    <div className="flex min-h-dvh flex-col bg-background text-foreground">
      <BreadcrumbList
        items={[
          { name: t("common.home"), url: siteConfig.url },
          { name: t("donate.title"), url: `${siteConfig.url}${getLocalizedPath("/donate", locale)}` },
        ]}
      />
      <StructuredData
        type="WebPage"
        data={{
          name: t("donate.title"),
          description: t("donate.description"),
          url: `${siteConfig.url}${getLocalizedPath("/donate", locale)}`,
        }}
      />
      <SiteHeader />

      <PageShell
        title={t("donate.title")}
        lede={t("donate.description")}
      >
        <div className="grid gap-6">
          <div className="relative h-48 w-full overflow-hidden rounded-3xl border border-border bg-surface sm:h-64">
            <Image
              src="/donation_banner_clear_966x499.png"
              alt={t("donate.about.text")}
              fill
              className="object-contain"
              sizes="(max-width: 768px) 100vw, 80vw"
            />
          </div>

          <SectionCard title={t("donate.about.title")}>
            <p className="text-muted-foreground">
              {t("donate.about.text", { email: siteConfig.supportEmail })}
            </p>
          </SectionCard>

          <SectionCard title={t("donate.disclaimer.title")}>
            <p className="text-muted-foreground">
              {t("donate.disclaimer.text")}
            </p>
          </SectionCard>

          <SectionCard title={t("donate.paymentMethod.title")}>
            <div className="flex flex-wrap gap-3">
              {PAYMENT_METHODS.map((method) => (
                <button
                  key={method}
                  onClick={() => {
                    setSelectedMethod(method);
                    if (
                      method === "bankTransfer" ||
                      method === "buyMeACoffee" ||
                      method === "kofi"
                    ) {
                      setSelectedPreset(null);
                      setIsCustomSelected(false);
                      setCustomAmount("");
                    }
                    if (method === "bankTransfer") {
                      // Bank details will show automatically
                    }
                  }}
                  className={`rounded-xl border px-4 py-2 text-sm font-medium transition-colors ${
                    selectedMethod === method
                      ? "border-accent bg-accent text-on-accent"
                      : "border-border bg-surface text-foreground hover:bg-muted"
                  }`}
                >
                  {t(`donate.paymentMethod.methods.${method}`)}
                </button>
              ))}
            </div>
          </SectionCard>

          {selectedMethod === "stripe" && (
            <SectionCard title={t("donate.selectAmount.title")}>
              <div className="flex flex-wrap gap-3">
                {PRESET_AMOUNTS.map((amount) => (
                  <button
                    key={amount}
                    onClick={() => {
                      setIsCustomSelected(false);
                      setSelectedPreset(amount);
                    }}
                    className={`rounded-xl border px-4 py-2 text-sm font-medium transition-colors ${
                      !isCustomSelected && selectedPreset === amount
                        ? "border-accent bg-accent text-on-accent"
                        : "border-border bg-surface text-foreground hover:bg-muted"
                    }`}
                  >
                    ${amount}
                  </button>
                ))}
                <button
                  onClick={() => {
                    setIsCustomSelected(true);
                    setSelectedPreset(null);
                  }}
                  className={`rounded-xl border px-4 py-2 text-sm font-medium transition-colors ${
                    isCustomSelected
                      ? "border-accent bg-accent text-on-accent"
                      : "border-border bg-surface text-foreground hover:bg-muted"
                  }`}
                >
                  {t("donate.selectAmount.custom")}
                </button>
              </div>

              {!isCustomSelected && selectedPreset !== null && (
                <div className="mt-4 flex items-center gap-2">
                  <input
                    type="checkbox"
                    id="monthly"
                    checked={isMonthly}
                    onChange={(e) => setIsMonthly(e.target.checked)}
                    className="h-4 w-4 rounded border-border text-accent focus:ring-accent"
                  />
                  <label
                    htmlFor="monthly"
                    className="text-sm text-foreground cursor-pointer"
                  >
                    {t("donate.selectAmount.monthly")}
                  </label>
                </div>
              )}
            </SectionCard>
          )}

          {selectedMethod === "bankTransfer" && (
            <SectionCard title={t("donate.bankTransfer.title")}>
              <div className="mb-4 flex gap-2 border-b border-border">
                <button
                  onClick={() => setBankTab("euro")}
                  className={`px-4 py-2 text-sm font-medium transition-colors ${
                    bankTab === "euro"
                      ? "border-b-2 border-accent text-accent"
                      : "text-muted-foreground hover:text-foreground"
                  }`}
                >
                  {t("donate.bankTransfer.euroAccount")}
                </button>
                <button
                  onClick={() => setBankTab("us")}
                  className={`px-4 py-2 text-sm font-medium transition-colors ${
                    bankTab === "us"
                      ? "border-b-2 border-accent text-accent"
                      : "text-muted-foreground hover:text-foreground"
                  }`}
                >
                  {t("donate.bankTransfer.usAccount")}
                </button>
              </div>

              {bankTab === "euro" ? (
                <div className="space-y-4">
                  <BankLine
                    label={t("donate.bankTransfer.accountHolder")}
                    value="NetCreatif"
                    onCopy={() => copyToClipboard("NetCreatif", t("donate.bankTransfer.accountHolder"))}
                  />
                  <BankLine
                    label={t("donate.bankTransfer.iban")}
                    value="BE44905608281145"
                    onCopy={() => copyToClipboard("BE44905608281145", t("donate.bankTransfer.iban"))}
                  />
                  <BankLine
                    label={t("donate.bankTransfer.bicSwift")}
                    value="TRWIBEB1XXX"
                    onCopy={() => copyToClipboard("TRWIBEB1XXX", t("donate.bankTransfer.bicSwift"))}
                  />
                </div>
              ) : (
                <div className="space-y-4">
                  <BankLine
                    label={t("donate.bankTransfer.name")}
                    value="NetCreatif"
                    onCopy={() => copyToClipboard("NetCreatif", t("donate.bankTransfer.name"))}
                  />
                  <BankLine
                    label={t("donate.bankTransfer.accountNumber")}
                    value="434315636491081"
                    onCopy={() =>
                      copyToClipboard("434315636491081", t("donate.bankTransfer.accountNumber"))
                    }
                  />
                  <BankLine
                    label={t("donate.bankTransfer.accountType")}
                    value="Deposit"
                    onCopy={() => copyToClipboard("Deposit", t("donate.bankTransfer.accountType"))}
                  />
                  <BankLine
                    label={t("donate.bankTransfer.routingNumber")}
                    value="084009519"
                    onCopy={() =>
                      copyToClipboard("084009519", t("donate.bankTransfer.routingNumber"))
                    }
                  />
                  <BankLine
                    label={t("donate.bankTransfer.bicSwift")}
                    value="TRWIUS35XXX"
                    onCopy={() => copyToClipboard("TRWIUS35XXX", t("donate.bankTransfer.bicSwift"))}
                  />
                </div>
              )}

              <p className="mt-4 text-sm text-muted-foreground">
                {t("donate.bankTransfer.note")}
              </p>
            </SectionCard>
          )}

          {selectedMethod !== "bankTransfer" && (
            <div className="flex justify-center">
              <button
                onClick={handleDonate}
                disabled={requiresAmount || !selectedMethod}
                className={`rounded-xl px-8 py-3 text-base font-semibold transition-colors ${
                  requiresAmount || !selectedMethod
                    ? "cursor-not-allowed bg-muted text-muted-foreground"
                    : "bg-accent text-on-accent hover:bg-accent/90"
                }`}
              >
                {t("donate.donateButton")}
              </button>
            </div>
          )}
        </div>
      </PageShell>

      <SiteFooter />
    </div>
  );
}

function BankLine({
  label,
  value,
  onCopy,
}: {
  label: string;
  value: string;
  onCopy: () => void;
}) {
  const [copied, setCopied] = useState(false);
  const { t } = useTranslations();

  const handleCopy = async () => {
    await onCopy();
    setCopied(true);
    setTimeout(() => {
      setCopied(false);
    }, 2000);
  };

  return (
    <div className="flex items-start justify-between gap-4">
      <div className="flex-1">
        <div className="text-xs font-semibold text-muted-foreground">
          {label}
        </div>
        <div className="mt-1 text-sm font-medium text-foreground">{value}</div>
      </div>
      <button
        onClick={handleCopy}
        className={`rounded-lg border px-3 py-1.5 text-xs font-medium transition-colors ${
          copied
            ? "border-accent bg-accent text-on-accent"
            : "border-border bg-surface text-foreground hover:bg-muted"
        }`}
      >
        {copied ? t("donate.bankTransfer.copied") : t("donate.bankTransfer.copy")}
      </button>
    </div>
  );
}

export default async function DonatePage({ params }: { params: Promise<{ locale: string }> }) {
  const { locale } = await params;
  const resolvedLocale = (locales.includes(locale as Locale) ? locale : defaultLocale) as Locale;

  return (
    <TranslationProvider locale={resolvedLocale}>
      <DonatePageContent locale={resolvedLocale} />
    </TranslationProvider>
  );
}

