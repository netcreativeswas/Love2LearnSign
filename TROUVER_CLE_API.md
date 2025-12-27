# 🔑 Comment trouver et régénérer la clé API Firebase

## Méthode 1 : Firebase Console (RECOMMANDÉ - Plus simple)

### Étape 1 : Accéder aux paramètres du projet
1. Va sur : https://console.firebase.google.com/
2. Sélectionne le projet **"Love to Learn Sign"** (ou `love-to-learn-sign`)

### Étape 2 : Ouvrir les paramètres du projet
1. Clique sur l'**icône d'engrenage ⚙️** en haut à gauche (à côté de "Project Overview")
2. Clique sur **"Project settings"** (Paramètres du projet)

### Étape 3 : Trouver la clé API Web
1. Dans l'onglet **"General"** (Général)
2. Descends jusqu'à la section **"Your apps"** (Vos applications)
3. Clique sur l'icône **Web** (</>) ou trouve l'app web
4. Tu verras la configuration Firebase avec :
   - `apiKey: 'AIza…'` ← C'est la clé à régénérer (ne colle pas la valeur complète dans un repo public)

### Étape 4 : Régénérer la clé
⚠️ **ATTENTION** : Firebase ne permet pas de régénérer directement la clé API depuis la console Firebase. Il faut passer par Google Cloud Console.

---

## Méthode 2 : Google Cloud Console (NÉCESSAIRE pour régénérer)

### Étape 1 : Accéder aux credentials
1. Va directement sur : https://console.cloud.google.com/apis/credentials?project=love-to-learn-sign
   
   OU
   
2. Va sur : https://console.cloud.google.com/
3. Sélectionne le projet **"Love to Learn Sign"** (en haut, dans le sélecteur de projet)
4. Dans le menu de gauche, va dans **"APIs & Services"** → **"Credentials"**

### Étape 2 : Trouver la clé API
1. Dans la section **"API keys"**, tu verras une liste de clés
2. Cherche la clé qui commence par `AIza` (et/ou celle associée à ton app Firebase)
   - Elle peut s'appeler "Browser key" ou "Web API Key" ou avoir un nom personnalisé
   - La clé commence par `AIza...`

### Étape 3 : Régénérer la clé
1. Clique sur le **nom de la clé** (pas sur l'icône, mais sur le texte du nom)
2. Tu arrives sur la page de détails de la clé
3. En haut, clique sur **"REGENERATE KEY"** (Régénérer la clé)
4. Confirme en cliquant sur **"Regenerate"**
5. **COPIE IMMÉDIATEMENT** la nouvelle clé (tu ne la reverras plus !)

---

## Méthode 3 : Si tu ne vois pas la clé dans la liste

### Vérifier le bon projet
1. En haut de la page Google Cloud Console, vérifie que le projet sélectionné est bien **"Love to Learn Sign"** (ID: `love-to-learn-sign`)
2. Si ce n'est pas le bon, clique sur le sélecteur de projet et choisis le bon

### Filtrer les clés
1. Dans la page "Credentials", utilise la barre de recherche en haut
2. Tape : `AIza` (ou le nom de la clé / “Browser key”)
3. Ou cherche par "Browser key" ou "Web API Key"

### Vérifier les permissions
1. Assure-toi d'être connecté avec un compte qui a les permissions **"Owner"** ou **"Editor"** sur le projet
2. Si tu n'as pas les permissions, demande à l'administrateur du projet

---

## Méthode 4 : Via Firebase CLI (si installé)

```bash
# Lister les projets Firebase
firebase projects:list

# Voir la configuration du projet
firebase use love-to-learn-sign
firebase apps:list
```

---

## ⚠️ IMPORTANT après régénération

Une fois que tu as la nouvelle clé :

1. **Mets à jour le fichier local** `dashboard/lib/firebase_options.dart` :
   - Remplace l’ancienne clé `AIza…` par la nouvelle (localement, ne la commit pas si le repo est public)

2. **Mets à jour aussi** (si tu les utilises) :
   - `app/lib/firebase_options.dart` (si ce fichier existe)
   - Tous les fichiers de configuration qui contiennent l'ancienne clé

3. **Teste l'application** pour vérifier que tout fonctionne avec la nouvelle clé

4. **Configure les restrictions** sur la nouvelle clé (voir SECURITY_FIX.md)

---

## 🔍 Si tu ne trouves toujours pas la clé

1. **Vérifie que tu es sur le bon compte Google** (celui qui a créé le projet Firebase)
2. **Vérifie l'ID du projet** : `love-to-learn-sign`
3. **Contacte le support Google Cloud** si nécessaire

---

## 📝 Note sur les clés API Firebase

- Les clés API Firebase pour le web sont généralement des "Browser keys"
- Elles sont différentes des clés de service account
- Une clé API peut être utilisée par plusieurs apps (web, Android, iOS) dans le même projet

