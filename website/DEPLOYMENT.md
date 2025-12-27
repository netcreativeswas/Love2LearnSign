# Guide de déploiement Vercel — love2learnsign.com

## Prérequis
- Un compte Vercel (gratuit) : https://vercel.com/signup
- Le domaine `love2learnsign.com` enregistré chez un registrar (ex: Namecheap, GoDaddy, Cloudflare, etc.)
- Accès à la gestion DNS de votre domaine

---

## Étape 1 : Créer le projet Vercel

### Option A : Via l'interface Vercel (recommandé)

1. **Connecter votre repo Git** :
   - Allez sur https://vercel.com/new
   - Connectez votre compte GitHub/GitLab/Bitbucket si ce n'est pas déjà fait
   - Sélectionnez le repository `L2LSign-merge`

2. **Configurer le projet** :
   - **Framework Preset** : Next.js (auto-détecté)
   - **Root Directory** : `website` ⚠️ **IMPORTANT** : Changez de `/` à `website/`
   - **Build Command** : `npm run build` (par défaut)
   - **Output Directory** : `.next` (par défaut)
   - **Install Command** : `npm install` (par défaut)

3. **Variables d'environnement** : Aucune nécessaire pour l'instant

4. Cliquez sur **Deploy**

### Option B : Via Vercel CLI

```bash
# Installer Vercel CLI (si pas déjà fait)
npm i -g vercel

# Dans le dossier website
cd /Users/jl/L2LSign-merge/website

# Déployer
vercel

# Suivre les prompts :
# - Link to existing project? No (première fois)
# - Project name: love2learnsign-website (ou autre)
# - Directory: ./
# - Override settings? No
```

---

## Étape 2 : Ajouter le domaine dans Vercel

1. **Dans votre projet Vercel** :
   - Allez dans **Settings** → **Domains**

2. **Ajouter le domaine** :
   - Cliquez sur **Add Domain**
   - Entrez : `love2learnsign.com`
   - Cliquez sur **Add**

3. **Ajouter www (optionnel mais recommandé)** :
   - Cliquez sur **Add Domain** à nouveau
   - Entrez : `www.love2learnsign.com`
   - Cliquez sur **Add**

4. **Vercel affichera les enregistrements DNS requis** :
   - Notez les valeurs exactes (elles varient selon votre configuration)
   - Exemple typique :
     - Pour `love2learnsign.com` (apex) : un **A record** ou **ALIAS/ANAME**
     - Pour `www.love2learnsign.com` : un **CNAME** pointant vers `cname.vercel-dns.com.`

---

## Étape 3 : Configurer DNS chez votre registrar

⚠️ **Important** : Utilisez les valeurs exactes affichées dans Vercel (Settings → Domains), pas les exemples ci-dessous.

### Exemple avec différents registrars :

#### **Namecheap**
1. Allez dans **Domain List** → Cliquez sur **Manage** à côté de `love2learnsign.com`
2. Onglet **Advanced DNS**
3. Ajoutez/modifiez :
   - **Type** : `A Record` | **Host** : `@` | **Value** : `[IP fourni par Vercel]` | **TTL** : Automatic
   - **Type** : `CNAME Record` | **Host** : `www` | **Value** : `[cname.vercel-dns.com.]` | **TTL** : Automatic

#### **GoDaddy**
1. Allez dans **My Products** → Cliquez sur **DNS** à côté de votre domaine
2. Dans **Records**, ajoutez/modifiez :
   - **Type** : `A` | **Name** : `@` | **Value** : `[IP fourni par Vercel]` | **TTL** : 1 Hour
   - **Type** : `CNAME` | **Name** : `www` | **Value** : `[cname.vercel-dns.com.]` | **TTL** : 1 Hour

#### **Cloudflare**
1. Sélectionnez votre domaine dans le dashboard
2. Onglet **DNS** → **Records**
3. Ajoutez/modifiez :
   - **Type** : `A` | **Name** : `@` | **IPv4 address** : `[IP fourni par Vercel]` | **Proxy status** : DNS only (gris) | **TTL** : Auto
   - **Type** : `CNAME` | **Name** : `www` | **Target** : `[cname.vercel-dns.com.]` | **Proxy status** : DNS only | **TTL** : Auto

#### **Autres registrars**
- Cherchez la section **DNS Management** / **DNS Records** / **Zone File**
- Ajoutez les enregistrements A et CNAME comme indiqué par Vercel

---

## Étape 4 : Vérifier la propagation DNS

1. **Attendre 5-60 minutes** (parfois jusqu'à 48h, mais généralement rapide)

2. **Vérifier** :
   ```bash
   # Vérifier l'apex domain
   dig love2learnsign.com +short
   
   # Vérifier www
   dig www.love2learnsign.com +short
   ```

3. **Dans Vercel** :
   - Allez dans **Settings** → **Domains**
   - Les domaines devraient passer de "Pending" à "Valid" (coche verte) une fois la propagation terminée

---

## Étape 5 : Configurer les redirections (optionnel)

1. **Dans Vercel** → **Settings** → **Domains**
2. Choisissez votre domaine principal (ex: `love2learnsign.com` sans www)
3. Configurez la redirection :
   - `www.love2learnsign.com` → `love2learnsign.com` (ou l'inverse selon votre préférence)

---

## Étape 6 : Vérifier le déploiement

Une fois le DNS propagé et Vercel validé :

1. **Visitez** :
   - `https://love2learnsign.com` → Devrait afficher la homepage
   - `https://love2learnsign.com/privacy` → Privacy Policy
   - `https://love2learnsign.com/delete-account` → Delete Account page
   - `https://love2learnsign.com/contact` → Contact page

2. **Vérifier HTTPS** : Vercel fournit automatiquement un certificat SSL (Let's Encrypt)

---

## Mise à jour du site (déploiements futurs)

### Via Git (automatique)
- Chaque `git push` sur la branche principale déclenchera un nouveau déploiement automatique
- Vercel détecte les changements dans `website/`

### Via Vercel CLI
```bash
cd /Users/jl/L2LSign-merge/website
vercel --prod
```

---

## Liens pour Google Play Console

Une fois déployé, utilisez ces URLs dans Google Play Console :

- **Privacy Policy** : `https://love2learnsign.com/privacy`
- **Delete Account** : `https://love2learnsign.com/delete-account`

---

## Dépannage

### Le domaine reste "Pending" dans Vercel
- Vérifiez que les enregistrements DNS sont corrects (utilisez `dig` ou un outil en ligne)
- Attendez jusqu'à 48h (rare)
- Vérifiez qu'il n'y a pas de conflits avec d'autres enregistrements DNS

### Erreur 404 sur le site
- Vérifiez que le **Root Directory** est bien `website/` dans les settings Vercel
- Vérifiez que le build réussit (onglet **Deployments** dans Vercel)

### HTTPS ne fonctionne pas
- Vercel configure automatiquement HTTPS, mais cela peut prendre quelques minutes après la validation du domaine
- Vérifiez dans **Settings** → **Domains** que le certificat SSL est émis

---

## Support

- Documentation Vercel : https://vercel.com/docs
- Support Vercel : https://vercel.com/support

