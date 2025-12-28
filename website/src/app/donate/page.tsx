"use client";

import { useState } from "react";
import { SiteFooter } from "@/components/SiteFooter";
import { SiteHeader } from "@/components/SiteHeader";
import { PageShell } from "@/components/PageShell";
import { SectionCard } from "@/components/SectionCard";
import Image from "next/image";

const STRIPE_CUSTOM_LINK = "https://donate.stripe.com/7sY9ANgkheEv2r40n38N208";
const STRIPE_LINKS: Record<number, string> = {
  2: "https://buy.stripe.com/9B63cpgkh2VNc1E1r78N200",
  5: "https://buy.stripe.com/bJe7sFc410NF8Ps6Lr8N201",
  10: "https://buy.stripe.com/14A8wJ2traof8Ps9XD8N202",
  20: "https://buy.stripe.com/7sYdR3c41dArc1Eb1H8N203",
};

const STRIPE_MONTHLY_LINKS: Record<number, string> = {
  2: "https://donate.stripe.com/28EaER0lj53Vd5I7Pv8N204",
  5: "https://donate.stripe.com/4gM00dd850NF4zc3zf8N205",
  10: "https://donate.stripe.com/6oU8wJaZX2VNfdQc5L8N206",
  20: "https://donate.stripe.com/3cI14hfgdbsj0iW6Lr8N207",
};

const PRESET_AMOUNTS = [2, 5, 10, 20];
const PAYMENT_METHODS = [
  "Buy me a coffee",
  "Ko-Fi.com",
  "Stripe",
  "Bank Transfer",
] as const;

type PaymentMethod = (typeof PAYMENT_METHODS)[number];

export default function DonatePage() {
  const [selectedMethod, setSelectedMethod] = useState<PaymentMethod | null>(
    null
  );
  const [selectedPreset, setSelectedPreset] = useState<number | null>(null);
  const [isCustomSelected, setIsCustomSelected] = useState(false);
  const [customAmount, setCustomAmount] = useState("");
  const [isMonthly, setIsMonthly] = useState(false);
  const [showBankDetails, setShowBankDetails] = useState(false);
  const [bankTab, setBankTab] = useState<"euro" | "us">("euro");

  const handleDonate = () => {
    if (!selectedMethod) return;

    let url: string | null = null;

    if (selectedMethod === "Buy me a coffee") {
      url = "https://buymeacoffee.com/netcreative";
    } else if (selectedMethod === "Ko-Fi.com") {
      url = "https://ko-fi.com/netcreativejlc";
    } else if (selectedMethod === "Stripe") {
      if (isCustomSelected) {
        url = STRIPE_CUSTOM_LINK;
      } else if (selectedPreset !== null) {
        if (isMonthly) {
          url = STRIPE_MONTHLY_LINKS[selectedPreset] || STRIPE_CUSTOM_LINK;
        } else {
          url = STRIPE_LINKS[selectedPreset] || STRIPE_CUSTOM_LINK;
        }
      }
    } else if (selectedMethod === "Bank Transfer") {
      setShowBankDetails(true);
      return;
    }

    if (url) {
      window.open(url, "_blank", "noopener,noreferrer");
    }
  };

  const copyToClipboard = async (text: string, label: string) => {
    try {
      await navigator.clipboard.writeText(text);
      // You could add a toast notification here
    } catch (err) {
      console.error("Failed to copy:", err);
    }
  };

  const requiresAmount =
    selectedMethod === "Stripe" && !isCustomSelected && selectedPreset === null;

  return (
    <div className="flex min-h-dvh flex-col bg-background text-foreground">
      <SiteHeader />

      <PageShell
        title="Donate"
        lede="Thank you for considering a donation. Your support helps improve the app and extend the dictionary to other sign languages."
      >
        <div className="grid gap-6">
          {/* Donation Banner Image */}
          <div className="relative h-48 w-full overflow-hidden rounded-3xl border border-border bg-surface sm:h-64">
            <Image
              src="/donation_banner_clear_966x499.png"
              alt="Donation"
              fill
              className="object-cover"
              sizes="(max-width: 768px) 100vw, 80vw"
            />
          </div>

          {/* Description */}
          <SectionCard title="About your donation">
            <p className="text-muted-foreground">
              Thank you for considering a donation. I created this app to help
              deaf people in Bangladesh develop their language skills and to
              help those who cannot sign and are isolated from the Deaf
              community by giving them the opportunity to learn proper sign
              language to communicate. Your donation will help me improve the
              app. I plan to extend this dictionary to other sign languages,
              mainly in Asia. If you have ideas or suggestions, please contact
              me at{" "}
              <a
                href="mailto:info@netcreative-swas.net"
                className="font-semibold text-foreground hover:underline"
              >
                info@netcreative-swas.net
              </a>
              .
            </p>
          </SectionCard>

          {/* Disclaimer */}
          <SectionCard title="Disclaimer">
            <p className="text-muted-foreground">
              My company Netcreatif is based in France and no donation will
              actually be going to a Bangladeshi bank account and is not subject
              to tax in Bangladesh.
            </p>
          </SectionCard>

          {/* Payment Method Selection */}
          <SectionCard title="Payment method">
            <div className="flex flex-wrap gap-3">
              {PAYMENT_METHODS.map((method) => (
                <button
                  key={method}
                  onClick={() => {
                    setSelectedMethod(method);
                    if (
                      method === "Bank Transfer" ||
                      method === "Buy me a coffee" ||
                      method === "Ko-Fi.com"
                    ) {
                      setSelectedPreset(null);
                      setIsCustomSelected(false);
                      setCustomAmount("");
                    }
                  }}
                  className={`rounded-xl border px-4 py-2 text-sm font-medium transition-colors ${
                    selectedMethod === method
                      ? "border-accent bg-accent text-on-accent"
                      : "border-border bg-surface text-foreground hover:bg-muted"
                  }`}
                >
                  {method}
                </button>
              ))}
            </div>
          </SectionCard>

          {/* Amount Selection (only for Stripe) */}
          {selectedMethod === "Stripe" && (
            <SectionCard title="Select amount">
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
                  Custom
                </button>
              </div>

              {/* Monthly checkbox (only for preset amounts) */}
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
                    Make this donation monthly
                  </label>
                </div>
              )}
            </SectionCard>
          )}

          {/* Bank Transfer Details */}
          {showBankDetails && (
            <SectionCard title="Bank Transfer Instructions">
              <div className="mb-4 flex gap-2 border-b border-border">
                <button
                  onClick={() => setBankTab("euro")}
                  className={`px-4 py-2 text-sm font-medium transition-colors ${
                    bankTab === "euro"
                      ? "border-b-2 border-accent text-accent"
                      : "text-muted-foreground hover:text-foreground"
                  }`}
                >
                  Euro Account
                </button>
                <button
                  onClick={() => setBankTab("us")}
                  className={`px-4 py-2 text-sm font-medium transition-colors ${
                    bankTab === "us"
                      ? "border-b-2 border-accent text-accent"
                      : "text-muted-foreground hover:text-foreground"
                  }`}
                >
                  US Account
                </button>
              </div>

              {bankTab === "euro" ? (
                <div className="space-y-4">
                  <BankLine
                    label="Account holder"
                    value="NetCreatif"
                    onCopy={() => copyToClipboard("NetCreatif", "Account holder")}
                  />
                  <BankLine
                    label="IBAN"
                    value="BE44905608281145"
                    onCopy={() => copyToClipboard("BE44905608281145", "IBAN")}
                  />
                  <BankLine
                    label="BIC/SWIFT"
                    value="TRWIBEB1XXX"
                    onCopy={() => copyToClipboard("TRWIBEB1XXX", "BIC/SWIFT")}
                  />
                </div>
              ) : (
                <div className="space-y-4">
                  <BankLine
                    label="Name"
                    value="NetCreatif"
                    onCopy={() => copyToClipboard("NetCreatif", "Name")}
                  />
                  <BankLine
                    label="Account number"
                    value="434315636491081"
                    onCopy={() =>
                      copyToClipboard("434315636491081", "Account number")
                    }
                  />
                  <BankLine
                    label="Account type"
                    value="Deposit"
                    onCopy={() => copyToClipboard("Deposit", "Account type")}
                  />
                  <BankLine
                    label="Routing number"
                    value="084009519"
                    onCopy={() =>
                      copyToClipboard("084009519", "Routing number")
                    }
                  />
                  <BankLine
                    label="BIC/Swift"
                    value="TRWIUS35XXX"
                    onCopy={() => copyToClipboard("TRWIUS35XXX", "BIC/Swift")}
                  />
                </div>
              )}

              <p className="mt-4 text-sm text-muted-foreground">
                Please mention &quot;Donation&quot; in the transfer reference.
              </p>

              <button
                onClick={() => setShowBankDetails(false)}
                className="mt-4 rounded-xl border border-border bg-surface px-4 py-2 text-sm font-medium text-foreground transition-colors hover:bg-muted"
              >
                Close
              </button>
            </SectionCard>
          )}

          {/* Donate Button */}
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
              Donate
            </button>
          </div>
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
  return (
    <div className="flex items-start justify-between gap-4">
      <div className="flex-1">
        <div className="text-xs font-semibold text-muted-foreground">
          {label}
        </div>
        <div className="mt-1 text-sm font-medium text-foreground">{value}</div>
      </div>
      <button
        onClick={onCopy}
        className="rounded-lg border border-border bg-surface px-3 py-1.5 text-xs font-medium text-foreground transition-colors hover:bg-muted"
      >
        Copy
      </button>
    </div>
  );
}

