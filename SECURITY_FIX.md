# 🔒 SECURITY FIX - API Key Exposure

## ✅ Actions prises

1. **Fichier retiré du Git** : `dashboard/lib/firebase_options.dart` (contient la clé API exposée)
2. **`.gitignore` mis à jour** : Les fichiers suivants sont maintenant ignorés :
   - `**/firebase_options.dart`
   - `**/google-services.json`
   - `**/GoogleService-Info.plist`

## ⚠️ ACTIONS URGENTES REQUISES

### 1. Régénérer la clé API compromise

La clé API `AIzaSyD2iaGZTa28Qino57AS7E1bzNTJct7vLD4` a été exposée publiquement et doit être régénérée.

**Étapes :**
1. Va sur https://console.cloud.google.com/apis/credentials
2. Sélectionne le projet "Love to Learn Sign" (ID: `love-to-learn-sign`)
3. Trouve la clé API `AIzaSyD2iaGZTa28Qino57AS7E1bzNTJct7vLD4`
4. Clique sur "Edit" puis "Regenerate Key"
5. **Copie la nouvelle clé** (tu ne la reverras plus)

### 2. Mettre à jour les fichiers locaux

Après avoir régénéré la clé, mets à jour :

- `dashboard/lib/firebase_options.dart` (fichier local, pas dans Git)
  - Remplace toutes les occurrences de `AIzaSyD2iaGZTa28Qino57AS7E1bzNTJct7vLD4` par la nouvelle clé

### 3. Configurer les restrictions de clé API (recommandé)

Dans Google Cloud Console, pour la nouvelle clé :
1. Va dans "API restrictions" → Restreint aux APIs nécessaires (Firebase, etc.)
2. Va dans "Application restrictions" → Restreint par :
   - **Android apps** : Package name `com.lovetolearnsign.app` + SHA-1
   - **iOS apps** : Bundle ID + App ID
   - **HTTP referrers** : Pour le web, liste les domaines autorisés

### 4. Vérifier l'usage de la clé compromise

1. Va sur https://console.cloud.google.com/apis/credentials
2. Clique sur la clé compromise
3. Vérifie "API usage" pour détecter tout usage suspect
4. Surveille la facturation pour des charges inattendues

### 5. Nettoyer l'historique Git (optionnel mais recommandé)

Le fichier reste dans l'historique Git. Pour le retirer complètement :

```bash
# ATTENTION : Cela réécrit l'historique Git
# Ne le fais que si tu es sûr et que personne d'autre n'a cloné le repo

git filter-branch --force --index-filter \
  "git rm --cached --ignore-unmatch dashboard/lib/firebase_options.dart" \
  --prune-empty --tag-name-filter cat -- --all

# Force push (ATTENTION : cela écrase l'historique)
git push origin --force --all
```

**Alternative plus sûre (BFG Repo-Cleaner) :**
```bash
# Installer BFG
brew install bfg

# Nettoyer
bfg --delete-files firebase_options.dart
git reflog expire --expire=now --all
git gc --prune=now --aggressive
git push origin --force --all
```

## 📝 Notes importantes

- **Le fichier `firebase_options.dart` doit être généré localement** et ne jamais être commité
- Utilise des variables d'environnement ou des fichiers de config locaux pour les secrets
- Pour Flutter, considère utiliser `flutterfire configure` qui génère ce fichier localement

## 🔍 Fichiers à surveiller

Les fichiers suivants contiennent des informations sensibles et ne doivent **JAMAIS** être commités :
- `**/firebase_options.dart`
- `**/google-services.json`
- `**/GoogleService-Info.plist`
- `**/key.properties`
- `**/*.keystore`
- `**/*.jks`

## ✅ Vérification

Après avoir régénéré la clé :
1. Vérifie que `firebase_options.dart` n'est plus dans Git : `git ls-files | grep firebase_options`
2. Vérifie que le fichier est bien ignoré : `git check-ignore dashboard/lib/firebase_options.dart`
3. Teste que l'app fonctionne toujours avec la nouvelle clé

