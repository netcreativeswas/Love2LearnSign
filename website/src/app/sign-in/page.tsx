"use client";

import { useEffect, useMemo, useState } from "react";
import { useRouter } from "next/navigation";
import { sendPasswordResetEmail, signInWithEmailAndPassword, onAuthStateChanged } from "firebase/auth";
import { auth } from "@/lib/firebase_client";

export default function SignInPage() {
  const router = useRouter();
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [showPassword, setShowPassword] = useState(false);
  const [loading, setLoading] = useState(false);
  const [message, setMessage] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);

  const canSubmit = useMemo(
    () => email.trim().length > 3 && password.length >= 6 && !loading,
    [email, password, loading]
  );

  useEffect(() => {
    // If already signed in, go straight to dashboard.
    const unsub = onAuthStateChanged(auth, (user) => {
      if (user) router.replace("/dashboard");
    });
    return () => unsub();
  }, [router]);

  async function onSubmit(e: React.FormEvent) {
    e.preventDefault();
    setError(null);
    setMessage(null);
    setLoading(true);
    try {
      await signInWithEmailAndPassword(auth, email.trim(), password);
      router.replace("/dashboard");
    } catch (err: any) {
      setError(err?.message ?? "Sign-in failed.");
    } finally {
      setLoading(false);
    }
  }

  async function onForgotPassword() {
    setError(null);
    setMessage(null);
    const trimmed = email.trim();
    if (!trimmed) {
      setError("Enter your email first.");
      return;
    }
    setLoading(true);
    try {
      await sendPasswordResetEmail(auth, trimmed);
      setMessage("Password reset email sent.");
    } catch (err: any) {
      setError(err?.message ?? "Failed to send password reset email.");
    } finally {
      setLoading(false);
    }
  }

  return (
    <main className="flex-1">
      <div className="mx-auto w-full max-w-5xl px-4 py-10 sm:py-14">
        <div className="mx-auto w-full max-w-md">
          <div className="rounded-2xl border border-border bg-surface p-6 shadow-sm">
          <div className="mb-5 space-y-2 text-left">
            <h2 className="text-xl font-semibold tracking-tight text-foreground">
              Sign In
            </h2>
            <p className="text-sm text-muted-foreground whitespace-nowrap overflow-hidden text-ellipsis">
              This area is for dashboard users only. If you don’t have an
              account, please contact support.
            </p>
          </div>

          <form onSubmit={onSubmit} className="space-y-4">
            <div className="space-y-1.5">
              <label className="text-sm font-medium text-foreground/90" htmlFor="email">
                Email
              </label>
              <input
                id="email"
                type="email"
                autoComplete="email"
                className="w-full rounded-lg border border-border bg-background px-3 py-2 text-sm outline-none focus:ring-2 focus:ring-[color:var(--color-accent)]"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                disabled={loading}
              />
            </div>

            <div className="space-y-1.5">
              <label className="text-sm font-medium text-foreground/90" htmlFor="password">
                Password
              </label>
              <div className="relative">
                <input
                  id="password"
                  type={showPassword ? "text" : "password"}
                  autoComplete="current-password"
                  className="w-full rounded-lg border border-border bg-background px-3 py-2 pr-11 text-sm outline-none focus:ring-2 focus:ring-[color:var(--color-accent)]"
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  disabled={loading}
                />
                <button
                  type="button"
                  className="absolute inset-y-0 right-0 flex items-center justify-center px-3 text-foreground/70 hover:text-foreground"
                  onClick={() => setShowPassword((v) => !v)}
                  aria-label={showPassword ? "Hide password" : "Show password"}
                  disabled={loading}
                >
                  {showPassword ? (
                    // Eye off
                    <svg
                      width="18"
                      height="18"
                      viewBox="0 0 24 24"
                      fill="none"
                      stroke="currentColor"
                      strokeWidth="2"
                      strokeLinecap="round"
                      strokeLinejoin="round"
                    >
                      <path d="M17.94 17.94A10.94 10.94 0 0 1 12 20c-7 0-11-8-11-8a21.77 21.77 0 0 1 5.06-5.94" />
                      <path d="M9.9 4.24A10.94 10.94 0 0 1 12 4c7 0 11 8 11 8a21.77 21.77 0 0 1-2.36 3.44" />
                      <path d="M14.12 14.12a3 3 0 0 1-4.24-4.24" />
                      <path d="M1 1l22 22" />
                    </svg>
                  ) : (
                    // Eye
                    <svg
                      width="18"
                      height="18"
                      viewBox="0 0 24 24"
                      fill="none"
                      stroke="currentColor"
                      strokeWidth="2"
                      strokeLinecap="round"
                      strokeLinejoin="round"
                    >
                      <path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z" />
                      <circle cx="12" cy="12" r="3" />
                    </svg>
                  )}
                </button>
              </div>
            </div>

            {error ? (
              <div className="rounded-lg border border-red-500/30 bg-red-500/10 px-3 py-2 text-sm text-foreground">
                {error}
              </div>
            ) : null}
            {message ? (
              <div className="rounded-lg border border-border bg-muted px-3 py-2 text-sm text-foreground">
                {message}
              </div>
            ) : null}

            <div className="flex items-center justify-between gap-3">
              <button
                type="button"
                onClick={onForgotPassword}
                className="text-sm font-medium text-foreground/80 underline-offset-4 hover:underline"
                disabled={loading}
              >
                Forgot password?
              </button>

              <button
                type="submit"
                disabled={!canSubmit}
                className="rounded-xl bg-[color:var(--color-accent)] px-5 py-2 text-sm font-semibold text-[color:var(--color-on-accent)] disabled:opacity-50"
              >
                {loading ? "Signing in…" : "Sign In"}
              </button>
            </div>
          </form>
        </div>
      </div>
      </div>
    </main>
  );
}


