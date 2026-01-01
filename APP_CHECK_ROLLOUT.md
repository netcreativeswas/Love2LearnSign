# App Check — Rollout complet (Website + Dashboard Web + App Android + App iOS)

Ce guide te dit **quoi faire en premier** et comment **lire App Check** dans Firebase Console, pour arriver à un état “tout embarqué” sans downtime.

## 0) À retenir (lecture rapide)
- **App Check protège**: Cloud Firestore / Storage / Functions (pas “l’écran login”).
- **reCAPTCHA protège**: un écran/flow précis (ex: signup). Ce n’est pas un remplacement d’App Check.
- **Règle d’or**: rester en **Monitoring** tant que tu n’as pas du trafic **Verified** venant de *chaque client* (website + dashboard + Android + iOS).

## 1) Comment lire ton écran Firebase App Check
Dans **Firebase Console → App Check**:

- **Your apps → Not registered**
  - Ça veut dire: l’app est connue de Firebase, mais **pas encore enregistrée** côté App Check.
  - Tant que c’est “Not registered”, l’app **n’enverra pas** d’attestation App Check.

- **APIs → Cloud Firestore → Monitoring (0% verified / 100% unverified)**
  - Ça veut dire: Firestore reçoit du trafic, mais **sans token App Check valide** (clients pas encore mis à jour, pas encore déployés, ou pas encore enregistrés).

- **Storage “Metrics will be displayed…”**
  - Soit pas de trafic Storage, soit trafic non visible / pas encore protégé.

## 2) Ordre CTO (le plus safe)
1) **Website + Dashboard Web** (rapide à redéployer, donc rapide à vérifier)
2) **Android** (Play Integrity: nécessite package + SHA-256 corrects)
3) **iOS** (App Attest/DeviceCheck: nécessite un device réel)
4) **Enforcement Firestore** une fois que Verified est bon partout

## 3) Website (Next.js) — App Check Web (reCAPTCHA v3)
### 3.1 Console (déjà fait chez toi)
- App Check → Web app → provider **reCAPTCHA v3**

### 3.2 Vercel (prod)
Dans Vercel → Project → **Settings → Environment Variables**:
- `NEXT_PUBLIC_RECAPTCHA_SITE_KEY` = ta **reCAPTCHA v3 site key** (publique)

Ensuite redeploy.

### 3.3 Vérification
- Ouvre le site et visite une page qui lit Firestore (ex: page “word” si utilisée)
- Firebase Console → App Check → **APIs → Cloud Firestore**:
  - tu dois voir **Verified requests** monter

Référence code: `website/src/lib/firebase_client.ts`

## 4) Dashboard Flutter Web embarqué dans le site (`/dashboard-app`)
Ton site Next.js embarque un build Flutter web sous `website/public/dashboard-app` (iframe).

### 4.1 Build dashboard avec la site key (obligatoire)
La **site key** reCAPTCHA v3 doit être injectée au build du dashboard.

Dans un terminal:
```bash
export L2L_RECAPTCHA_SITE_KEY="TA_SITE_KEY_RECAPTCHA_V3"
./website/scripts/build_dashboard_web.sh
```

Puis redeploy le website (Vercel).

Référence:
- script: `website/scripts/build_dashboard_web.sh`
- init App Check: `dashboard/lib/main.dart`

### 4.2 Vérification
- Ouvre `https://love2learnsign.com/dashboard` (ou ton route dashboard)
- Vérifie que **Verified** augmente dans App Check → Firestore

## 5) Android — Play Integrity
### 5.1 Enregistrement App Check (obligatoire)
Firebase Console → App Check → **Your apps**:
- `Love2LearnSign (com.love2learnsign.app)` → **Register**
- Provider: **Play Integrity**

### 5.2 SHA-256 (obligatoire)
Firebase Console → Project settings → **Your apps → Android**:
- ajoute les **SHA-256** nécessaires:
  - **debug** (pour tests en local si tu utilises debug provider)
  - **release / production**: souvent via **Play App Signing** (certificat d’app signing)

Astuce (debug keystore local):
```bash
cd app/android
./gradlew signingReport
```

### 5.3 Validation
- Installe une build sur un device
- Fais une action qui lit Firestore
- App Check → APIs → Firestore: **Verified** doit monter

Référence code: `app/lib/main.dart` (active Play Integrity en release)

## 6) iOS — App Attest / DeviceCheck
### 6.1 Enregistrement App Check
Firebase Console → App Check → Your apps:
- `Love2LearnSign-ios` → **Register**
- Provider: **App Attest** (fallback: DeviceCheck si nécessaire)

### 6.2 Validation
- Obligatoire: **device iOS réel** (pas simulateur)
- Ouvre l’app, fais une action Firestore, vérifie Verified côté Firestore

Référence code: `app/lib/main.dart` (AppleProvider.appAttest en release)

## 7) Enforcement Firestore (quand Monitoring est OK)
Quand tu vois que website + dashboard + Android + iOS génèrent du trafic **Verified**:
- App Check → APIs → **Cloud Firestore**:
  - passer **Monitoring → Enforced**

### 7.0 Checklist “GO / NO-GO”
Avant de cliquer “Enforce”, assure-toi que:
- tu as redeploy le website avec `NEXT_PUBLIC_RECAPTCHA_SITE_KEY`
- tu as rebuild le dashboard web **avec** `L2L_RECAPTCHA_SITE_KEY` (sinon il restera unverified)
- Android est **Registered** dans App Check (Play Integrity) et le bon **SHA-256** est ajouté dans Firebase
- iOS est **Registered** et tu as validé sur un device réel
- dans App Check → Firestore, tu vois un minimum de **Verified requests** venant de tes usages réels

### 7.1 Rollback plan
Si tu casses des vieux clients:
- repasse Firestore sur **Monitoring** immédiatement

### 7.2 Comment “forcer” du trafic pour tester (utile si % reste à 0)
Tu dois déclencher une **lecture Firestore** depuis chaque client:
- **Website**: ouvrir une route qui lit Firestore (ex: page “word” si tu l’utilises)
- **Dashboard**: ouvrir `/dashboard` et charger une page qui liste/édite des données Firestore
- **Android/iOS**: ouvrir l’app, naviguer vers une page qui fait une requête Firestore

## 8) Après Firestore (plus tard)
- **Storage**: Monitoring → Verified → Enforced
- **Functions**: protéger tes endpoints (ex: `verifyCaptcha`, `checkRateLimit`) en validant App Check côté serveur


