# Setup Git + GitHub pour déploiement Vercel

## Option 1 : Push vers GitHub (recommandé)

### Étape 1 : Initialiser Git (si pas déjà fait)

```bash
cd /Users/jl/L2LSign-merge

# Initialiser Git
git init

# Créer un .gitignore si pas déjà présent
cat > .gitignore << 'EOF'
# Dependencies
node_modules/
website/node_modules/

# Build outputs
.next/
website/.next/
out/
website/out/
dist/
website/dist/

# Environment variables
.env
.env.local
.env*.local

# IDE
.vscode/
.idea/
*.swp
*.swo

# OS
.DS_Store
Thumbs.db

# Logs
*.log
npm-debug.log*
yarn-debug.log*
yarn-error.log*

# Flutter
app/.dart_tool/
app/.flutter-plugins
app/.flutter-plugins-dependencies
app/build/
app/.packages
app/.pub-cache/
app/.pub/
app/pubspec.lock

# Firebase
.firebase/
firebase-debug.log
firestore-debug.log
ui-debug.log
EOF

# Ajouter tous les fichiers
git add .

# Premier commit
git commit -m "Initial commit: Add Love to Learn Sign showcase website"
```

### Étape 2 : Créer un repo sur GitHub

1. Allez sur https://github.com/new
2. Créez un nouveau repository (ex: `L2LSign-merge` ou `love2learnsign-website`)
3. **Ne cochez PAS** "Initialize with README" (le repo est déjà initialisé localement)
4. Cliquez sur **Create repository**

### Étape 3 : Connecter et push

```bash
cd /Users/jl/L2LSign-merge

# Ajouter le remote (remplacez USERNAME et REPO_NAME)
git remote add origin https://github.com/USERNAME/REPO_NAME.git

# Ou avec SSH (si vous avez configuré les clés SSH)
# git remote add origin git@github.com:USERNAME/REPO_NAME.git

# Push vers GitHub
git branch -M main
git push -u origin main
```

### Étape 4 : Déployer sur Vercel

Maintenant que le code est sur GitHub :

1. Allez sur https://vercel.com/new
2. Connectez votre compte GitHub
3. Sélectionnez le repository que vous venez de créer
4. **Important** : Configurez le **Root Directory** à `website/`
5. Cliquez sur **Deploy**

---

## Option 2 : Déployer directement via Vercel CLI (sans Git)

Si vous ne voulez pas utiliser Git pour l'instant :

```bash
cd /Users/jl/L2LSign-merge/website

# Installer Vercel CLI (si pas déjà fait)
npm i -g vercel

# Déployer
vercel

# Suivre les prompts :
# - Set up and deploy? Yes
# - Which scope? [Votre compte]
# - Link to existing project? No
# - Project name: love2learnsign-website
# - Directory: ./
# - Override settings? No

# Pour déployer en production
vercel --prod
```

**Note** : Avec cette méthode, vous devrez redéployer manuellement à chaque changement (pas de déploiements automatiques).

---

## Recommandation

**Option 1 (GitHub)** est recommandée car :
- ✅ Déploiements automatiques à chaque `git push`
- ✅ Historique des versions
- ✅ Facilite la collaboration
- ✅ Backup du code

