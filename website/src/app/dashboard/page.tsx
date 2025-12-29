"use client";

import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import { onAuthStateChanged, signOut } from "firebase/auth";
import { auth } from "@/lib/firebase_client";

export default function DashboardWrapper() {
  const router = useRouter();
  const [ready, setReady] = useState(false);
  const [authed, setAuthed] = useState(false);
  const [forceHide, setForceHide] = useState(false);

  function isSignedOutMessage(data: unknown): data is { type: "SIGNED_OUT" } {
    return (
      !!data &&
      typeof data === "object" &&
      "type" in data &&
      (data as Record<string, unknown>).type === "SIGNED_OUT"
    );
  }

  useEffect(() => {
    const unsub = onAuthStateChanged(auth, (user) => {
      setAuthed(!!user);
      setReady(true);
      if (!user) {
        router.replace("/sign-in");
      }
    });
    return () => unsub();
  }, [router]);

  useEffect(() => {
    async function onMessage(ev: MessageEvent) {
      const data: unknown = ev.data;
      if (isSignedOutMessage(data)) {
        setForceHide(true);
        // Ensure the parent window is actually signed out too (prevents bounce back to /dashboard).
        try {
          await signOut(auth);
        } catch {
          // ignore
        }
        router.replace("/sign-in");
      }
    }
    window.addEventListener("message", onMessage);
    return () => window.removeEventListener("message", onMessage);
  }, [router]);

  if (!ready) {
    return (
      <main className="flex min-h-[70vh] items-center justify-center px-4">
        <div className="rounded-2xl border border-border bg-surface px-5 py-4 text-sm text-muted-foreground">
          Loading dashboard…
        </div>
      </main>
    );
  }

  if (!authed) {
    // Redirect handled in effect; render nothing to avoid flicker.
    return null;
  }

  if (forceHide) {
    return null;
  }

  return (
    <main className="h-dvh">
      <iframe
        title="Love to Learn Sign Dashboard"
        src="/dashboard-app/index.html"
        className="h-full w-full border-0"
      />
    </main>
  );
}


