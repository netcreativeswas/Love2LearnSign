import { redirect } from "next/navigation";

export default function DashboardEntry() {
  // The Flutter Web admin dashboard is served as static files under /public/dashboard/.
  redirect("/dashboard/index.html");
}


