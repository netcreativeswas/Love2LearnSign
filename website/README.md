## Love to Learn Sign — Showcase Website

This folder (`website/`) contains the public showcase website for the **Love to Learn Sign** mobile app (**Developer:** NetCreatif).

### Pages
- `/` — Homepage
- `/contact` — Contact page
- `/privacy` — Privacy Policy
- `/delete-account` — Account deletion instructions (Google Play requirement)

## Getting Started

Run the development server:

```bash
npm run dev
```

Then open `http://localhost:3000`.

### Firebase App Check (recommended)
This website uses Firebase directly from the browser, so enabling **App Check** helps reduce automated abuse.

For the full rollout (website + embedded dashboard + mobile apps), see:
- `APP_CHECK_ROLLOUT.md` (repo root)

**1) Firebase Console**
- Firebase Console → **App Check**
- Register the **Web app**
- Provider: **reCAPTCHA v3**
- Keep it in **Monitoring** first (don’t enforce immediately)

**2) reCAPTCHA keys**
- The Firebase Console configuration uses the **reCAPTCHA secret key**
- The website code uses the **reCAPTCHA site key** (public)

**3) Website environment variable**
Create a local `website/.env.local` file (or set env vars in Vercel) with:
- `NEXT_PUBLIC_RECAPTCHA_SITE_KEY=...` (your reCAPTCHA v3 **site key**)

Optional (local dev only):
- `NEXT_PUBLIC_FIREBASE_APPCHECK_DEBUG_TOKEN=true`

**4) Enforcement**
Once you see valid traffic in the App Check dashboards, enable **Enforcement** for the Firebase services you use (commonly Firestore/Storage).

### Configuration
Edit the main site constants (domain, Play Store link, support email) here:
- `src/lib/site-config.ts`

### Design / colors
The website uses the same primary/accent palette as the Flutter app (from `app/lib/theme.dart`) and keeps a modern minimal style.

## Deploy on Vercel + connect `love2learnsign.com`

### 1) Create the Vercel project
- In Vercel, create a new project from this Git repository.
- Set the **Root Directory** to `website/`.
- Framework preset: **Next.js** (Vercel will auto-detect).

### 2) Add the domain in Vercel
- In your Vercel project: **Settings → Domains**
- Add:
  - `love2learnsign.com`
  - (optional) `www.love2learnsign.com`

### 3) Update DNS at your domain registrar
After adding the domain, Vercel will display the exact DNS records required for your setup.

Typical setup is:
- An **A / ALIAS / ANAME** record for the apex domain (`love2learnsign.com`)
- A **CNAME** record for `www` pointing to the Vercel domain target shown in Vercel

Important: use the exact values shown in Vercel’s domain screen, since they can vary by provider and configuration.

### 4) Redirect `www` (optional)
In Vercel **Domains**, choose your preferred primary domain and configure redirects as desired:
- `www.love2learnsign.com` → `love2learnsign.com`

### 5) Google Play Console links
Once deployed and the domain is connected, you can use:
- `https://love2learnsign.com/privacy`
- `https://love2learnsign.com/delete-account`
