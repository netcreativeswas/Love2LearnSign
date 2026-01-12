"use client";

import Image from "next/image";
import Link from "next/link";
import { usePathname } from "next/navigation";
import { siteConfig } from "@/lib/site-config";
import { TranslationProvider, useTranslations } from "./TranslationProvider";
import { getLocaleFromPath, getLocalizedPath } from "@/lib/i18n";

function SiteFooterContent() {
  const pathname = usePathname();
  const locale = getLocaleFromPath(pathname);
  const { t } = useTranslations();
  return (
    <footer className="mt-auto border-t border-border/70 bg-surface">
      <div className="mx-auto max-w-5xl px-4 py-6">
        {/* Top row */}
        <div className="mb-6 grid gap-6 sm:grid-cols-[30%_70%]">
          {/* Left side - Logo and description (centered) */}
          <div className="flex flex-col items-center gap-2 text-center">
            <div className="flex items-center gap-3">
              <Image
                src="/brand/logo.png"
                alt={t("common.logoAlt", { appName: siteConfig.appName })}
                width={48}
                height={48}
                className="rounded-full object-cover"
              />
              <div className="text-lg font-semibold text-foreground">
                {t("common.appName")}
              </div>
            </div>
            <p className="max-w-md text-sm leading-6 text-muted-foreground">
              {t("footer.description")}
            </p>
          </div>

          {/* Right side - Support and Donate (centered container, align-start content) */}
          <div className="flex items-center justify-center">
            <div className="flex flex-col items-start gap-2">
              <div className="flex items-center gap-2 text-sm">
                <span className="font-semibold text-foreground">{t("common.support")}:</span>
                <a
                  className="font-medium text-foreground hover:underline"
                  href={`mailto:${siteConfig.supportEmail}`}
                >
                  {siteConfig.supportEmail}
                </a>
              </div>
              <Link
                href={getLocalizedPath("/donate", locale)}
                className="text-sm font-medium text-foreground hover:underline"
              >
                {t("common.donate")}
              </Link>
            </div>
          </div>
        </div>

        {/* Bottom row - Centered links */}
        <div className="flex flex-col items-center gap-3 border-t border-border/50 pt-4">
          <div className="flex flex-wrap items-center justify-center gap-x-6 gap-y-2 text-sm">
            <Link
              className="text-foreground/90 hover:underline"
              href={getLocalizedPath("/privacy", locale)}
            >
              {t("common.privacy")}
            </Link>
            <Link
              className="text-foreground/90 hover:underline"
              href={getLocalizedPath("/delete-account", locale)}
            >
              {t("common.deleteAccount")}
            </Link>
            <Link
              className="text-foreground/90 hover:underline"
              href={getLocalizedPath("/contact", locale)}
            >
              {t("common.contact")}
            </Link>
            <Link
              className="text-foreground/90 hover:underline"
              href={getLocalizedPath("/collaboration", locale)}
            >
              {t("common.collaboration")}
            </Link>
            <a
              className="text-foreground/90 hover:underline"
              href={siteConfig.playStoreUrl}
              target="_blank"
              rel="noreferrer"
            >
              {t("common.googlePlay")}
            </a>
          </div>

          {/* Social icons */}
          <div className="flex flex-wrap items-center justify-center gap-3">
            {siteConfig.socialLinks.map((item) => (
              <a
                key={item.id}
                href={item.href}
                target="_blank"
                rel="noreferrer"
                aria-label={t(`social.${item.id}`)}
                className="rounded-xl border border-border bg-surface p-2 transition-colors hover:bg-muted"
              >
                <Image
                  src={item.iconSrc}
                  alt={t(`social.${item.id}`)}
                  width={22}
                  height={22}
                  className="h-[22px] w-[22px]"
                />
              </a>
            ))}
          </div>

          <div className="text-xs text-muted-foreground">
            {(() => {
              const company = "NetCreative";
              const text = t("footer.madeByLine", { netcreative: company });
              if (typeof text !== "string" || !text.includes(company)) {
                const token = "__NAME__";
                const template = t("common.madeBy", { name: token });
                const safeTemplate = typeof template === "string" ? template : `${t("common.madeBy")} ${token}`;
                const [before, after] = safeTemplate.split(token);
                return (
                  <>
                    {before}
                    <a
                      href="https://netcreative-swas.net"
                      target="_blank"
                      rel="noreferrer"
                      className="font-medium text-foreground hover:underline"
                    >
                      {company}
                    </a>
                    {after}
                  </>
                );
              }
              const [before, after] = text.split(company);
              return (
                <>
                  {before}
                  <a
                    href="https://netcreative-swas.net"
                    target="_blank"
                    rel="noreferrer"
                    className="font-medium text-foreground hover:underline"
                  >
                    {company}
                  </a>
                  {after}
                </>
              );
            })()}
          </div>
        </div>
      </div>
    </footer>
  );
}

export function SiteFooter() {
  const pathname = usePathname();
  const locale = getLocaleFromPath(pathname);

  return (
    <TranslationProvider locale={locale}>
      <SiteFooterContent />
    </TranslationProvider>
  );
}


