import { redirect } from "next/navigation";

export default function AdminRedirect() {
  // Backward-compatible shortcut (older dashboard was hosted under /admin).
  redirect("/dashboard");
}


