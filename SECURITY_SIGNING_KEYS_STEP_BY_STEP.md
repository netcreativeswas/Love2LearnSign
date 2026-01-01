# Sécurité — `key.properties` a été poussé (incident) : quoi faire étape par étape

Ce document est écrit “comme si c’était la première fois”. Suis les étapes **dans l’ordre**.

## Ce qui s’est passé (en 1 phrase)
Le fichier `app/android/key.properties` contenait des **mots de passe de signature** et a été **poussé** dans Git (donc il peut être récupéré dans l’historique). On doit donc:
1) empêcher que ça se reproduise,
2) enlever ce fichier de **l’historique Git**,
3) **remplacer/rotater** la clé d’upload Play (car le mot de passe a fuité).

> Important: même si le fichier `.jks` est “local”, une fuite de mot de passe reste grave. On traite ça comme compromis.

---

## Partie 1 — Empêcher que ça se reproduise (simple)

### 1.1 Vérifier que Git ignore déjà `key.properties`
Dans le repo, tu dois avoir (c’est OK):
- `.gitignore` contient `**/key.properties`
- `app/android/.gitignore` contient `key.properties`

➡️ Ça empêche les “nouveaux” commits, **mais** ça n’empêche pas un fichier déjà committé dans le passé.

### 1.2 Recréer `key.properties` en local (sans le committer)
Tu dois avoir **deux fichiers** dans `app/android/`:
- `key.properties.example` (dans le repo, avec `CHANGE_ME`)
- `key.properties` (local seulement, avec tes vrais chemins/mots de passe)

#### Option A — via Finder (sans terminal)
1) Va dans le dossier: `Love2LearnSign/app/android/`
2) Duplique `key.properties.example`
3) Renomme la copie en: `key.properties`
4) Ouvre `key.properties` et remplis:
   - `storeFile=/chemin/absolu/vers/ton/upload-key.jks`
   - `storePassword=...`
   - `keyAlias=...`
   - `keyPassword=...`
5) **Ne pousse jamais** ce fichier.

#### Option B — via terminal (plus fiable)
1) Ouvre un terminal
2) Va à la racine du repo:

```bash
cd /Users/jl/Love2LearnSign
```

3) Crée le fichier local à partir de l’exemple:

```bash
cp app/android/key.properties.example app/android/key.properties
```

4) Édite `app/android/key.properties` (dans ton éditeur) et remplis les valeurs.

### 1.3 Vérifier que `key.properties` ne sera pas committé
Dans le terminal, toujours à la racine du repo:

```bash
cd /Users/jl/Love2LearnSign
git status
```

✅ Résultat attendu:
- **tu ne dois PAS voir** `app/android/key.properties` dans “Changes to be committed” ou “Untracked files”.

Si tu le vois quand même, dis-moi et on corrige.

### 1.4 “Filet de sécurité” automatique
Le repo contient maintenant une vérification CI qui **bloque** un push si:
- `app/android/key.properties` est tracké
- un fichier `.jks/.p12/.pem/...` est tracké
- `storePassword=` ou `keyPassword=` apparaît dans des fichiers trackés

Ça te protège contre une erreur humaine.

---

## Partie 2 — Retirer `key.properties` de l’historique Git (obligatoire)
Supprimer le fichier “aujourd’hui” ne suffit pas: le secret est encore dans les anciens commits.

### 2.1 Préparer: être à la racine du repo

```bash
cd /Users/jl/Love2LearnSign
```

### 2.2 Sauvegarde de sécurité (recommandé)
Avant de réécrire l’historique, fais une copie du dossier du repo (Finder → dupliquer) OU un zip.

### 2.3 Installer l’outil `git-filter-repo`
Sur macOS, le plus simple:

```bash
brew install git-filter-repo
```

### 2.4 Réécrire l’historique pour supprimer le fichier partout
Toujours à la racine:

```bash
git filter-repo --path app/android/key.properties --invert-paths --force
```

### 2.5 Pousser l’historique nettoyé (force-push)
⚠️ Ceci réécrit l’histoire du repo. À faire quand tu es prêt.

```bash
cd /Users/jl/Love2LearnSign && git remote add origin git@github.com:netcreativeswas/Love2LearnSign.git && git remote -v
git push --force --all
git push --force --tags
```

### 2.6 Important: les autres machines doivent se resynchroniser
Toute personne qui a cloné le repo doit:
- soit recloner,
- soit faire un reset très propre (recommandé: reclone).

### 2.7 Vérification rapide

```bash
git log -- app/android/key.properties
```

✅ Résultat attendu: **plus aucun commit** ne référence ce fichier.

---

## Partie 3 — Rotation de la clé d’upload Play (parce que le mot de passe a fuité)
Tu m’as confirmé que tu utilises **Play App Signing**. C’est une bonne nouvelle:
- le “vrai” **app signing key** est géré par Google,
- toi tu utilises une **upload key** pour envoyer des AAB sur le Play Console.

Comme le mot de passe a fuité, on remplace l’upload key.

### 3.1 Générer une nouvelle upload key (nouveau fichier `.jks`)
Dans un terminal:

```bash
mkdir -p /Users/jl/secrets/l2l/android
cd /Users/jl/secrets/l2l/android
```

Puis génère une nouvelle clé (choisis un mot de passe fort, garde-le en password manager):

```bash
keytool -genkeypair \
  -alias upload \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000 \
  -keystore upload-key-v2.jks
```

### 3.2 Exporter le certificat public (fichier `.pem`) à donner à Play

```bash
keytool -export -rfc \
  -alias upload \
  -file upload_certificate_v2.pem \
  -keystore upload-key-v2.jks
```

### 3.3 Mettre à jour Play Console (reset upload key)
Dans Play Console:
1) Ton app → **Test and release** → **App integrity** → **App signing**
2) Cherche “Upload key” / “Reset upload key” / “Update upload key”
3) Upload le fichier `upload_certificate_v2.pem`

> Play peut demander une validation. Suis l’assistant, c’est normal.

### 3.4 Mettre à jour ton `key.properties` local
Dans `app/android/key.properties` (local seulement):
- `storeFile=/Users/jl/secrets/l2l/android/upload-key-v2.jks`
- mets le nouveau mot de passe (storePassword/keyPassword)

### 3.5 Mettre à jour Firebase (SHA) — comprendre quoi coller où
Tu as vu des SHA-1/SHA-256 dans Play Console. Il y a 2 certificats:
- **App signing key certificate** (celui qui signe les apps installées par les utilisateurs)
- **Upload key certificate** (celui qui sert juste à upload)

En général, dans Firebase → Project settings → Android app → Add fingerprint:
- ajoute **au minimum** SHA-1 + SHA-256 du **App signing key certificate**
- ajoute aussi debug SHA-1/SHA-256 si tu veux que Google Sign-In marche en debug.

Tu as déjà ajouté SHA depuis Play Console, c’est OK.

---

## “Checklist” ultra courte (si tu es pressé)
1) Push un commit qui **supprime** `key.properties` du repo + garde seulement `key.properties.example`.
2) Réécris l’historique avec `git filter-repo` et force-push.
3) Génère `upload-key-v2.jks`, exporte `upload_certificate_v2.pem`, et mets à jour Play Console.
4) Mets à jour ton `app/android/key.properties` local avec le nouveau `.jks`.


