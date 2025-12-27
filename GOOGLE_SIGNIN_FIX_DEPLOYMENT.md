# 🔧 Google Sign-In Fix - Deployment Guide

## 📋 Problèmes Corrigés

### 1. **Document utilisateur manquant lors du premier Google Sign-In**
- **Symptôme** : `User document not found` et `PERMISSION_DENIED` lors de la première connexion
- **Cause** : Le document Firestore n'est pas créé automatiquement lors du Google Sign-In
- **Solution** : Détection automatique et redirection vers la page de sélection pays/type d'utilisateur

### 2. **Règles Firestore trop restrictives**
- **Symptôme** : `PERMISSION_DENIED` lors de la vérification d'existence du document
- **Cause** : Les règles vérifient `resource.data.uid` alors que `resource` est `null` si le document n'existe pas
- **Solution** : Règles modifiées pour permettre la vérification d'existence

### 3. **Timeouts Google Sign-In**
- **Ajout** : Timeouts sur toutes les opérations réseau (2 minutes pour sign-in, 30s pour les autres opérations)

### 4. **reCAPTCHA qui tourne indéfiniment**
- **Ajout** : Timeout de 3 minutes, détection des erreurs de chargement, UI de retry

## 🚀 Étapes de Déploiement

### **Étape 1 : Mettre à jour les règles Firestore** (CRITIQUE)

1. Allez sur [Firebase Console](https://console.firebase.google.com/)
2. Sélectionnez votre projet **Love to Learn Sign**
3. Dans le menu de gauche : **Firestore Database** → **Règles**
4. Copiez le contenu du fichier `app/firestore.rules` dans l'éditeur
5. **Cliquez sur "Publier"**

⚠️ **IMPORTANT** : Sans cette étape, le Google Sign-In continuera à échouer !

### **Étape 2 : Recompiler l'application**

```bash
cd /Users/jl/L2LSign-merge/app
flutter clean
flutter pub get
flutter build apk  # ou flutter run pour tester
```

### **Étape 3 : Tester le flux complet**

1. **Désinstaller l'ancienne version** de l'app sur votre appareil
2. **Installer la nouvelle version**
3. **Tester le Google Sign-In** :
   - Cliquez sur "Sign in with Google"
   - Sélectionnez votre compte Google
   - ✅ Vous devriez être redirigé vers la page de sélection pays/type d'utilisateur
   - Remplissez les informations
   - ✅ Le document utilisateur devrait être créé dans Firestore

## 🔍 Vérifications Post-Déploiement

### Vérifier dans Firebase Console

1. **Firestore Database** → Collection `users`
2. Après le Google Sign-In, un nouveau document devrait apparaître :
   - ID : `[DisplayName]__[UID]` (ex: `Jean_luc__jrEMG1NAMSchdmbKIZkVnpBb5kF3`)
   - Champs :
     ```
     {
       uid: "jrEMG1NAMSchdmbKIZkVnpBb5kF3",
       email: "anycreative.test@gmail.com",
       displayName: "Jean luc",
       country: "United States",
       userType: "hearing_impaired",
       roles: [],
       status: "pending",
       approved: false,
       provider: "google",
       photoUrl: "https://...",
       createdAt: [timestamp],
       updatedAt: [timestamp]
     }
     ```

### Vérifier les logs

Logs attendus lors d'un Google Sign-In réussi :
```
🔑 Starting Google Sign-In (Mobile)...
✅ Google account selected: user@example.com
🔑 Signing in to Firebase with Google credential...
✅ Firebase sign-in successful
🔍 AuthProvider: Fetching user roles...
⚠️ No user profile found - redirecting to country selection
```

## 🐛 Dépannage

### Problème : Toujours "PERMISSION_DENIED"
**Solution** : Vérifiez que les règles Firestore ont été publiées. Attendez 1-2 minutes après la publication.

### Problème : "User document not found" persiste
**Solution** : 
1. Allez dans Firestore
2. Créez manuellement le document pour tester : Collection `users` → Document `TestUser__[UID]`
3. Ajoutez les champs requis (voir structure ci-dessus)

### Problème : Erreurs réseau "Unable to resolve host firestore.googleapis.com"
**Solution** : 
- Vérifiez la connexion internet de l'appareil
- Ces erreurs sont normales pendant les reconnexions Firestore
- Si persistantes, redémarrez l'app

### Problème : Google Sign-In timeout
**Solution** : 
- Les nouveaux timeouts afficheront un message d'erreur clair après 2 minutes
- Vérifiez la connexion internet
- Réessayez la connexion

## 📊 Changements de Code

### Fichiers Modifiés

1. **`app/lib/widgets/captcha_challenge.dart`** : Timeouts et gestion d'erreurs reCAPTCHA
2. **`shared/lib/auth/auth_service.dart`** : Timeouts Google Sign-In
3. **`shared/lib/auth/auth_provider.dart`** : Détection document manquant
4. **`app/lib/signup_page.dart`** : Meilleure gestion erreurs CAPTCHA
5. **`app/firestore.rules`** : Règles assouplies pour vérification existence

### Nouveaux Comportements

- **Timeout CAPTCHA** : 3 minutes max (avant : infini)
- **Timeout Google Sign-In** : 2 minutes max (avant : infini)
- **Timeout opérations réseau** : 30 secondes (avant : infini)
- **Détection document manquant** : Redirection automatique vers sélection pays
- **Logs détaillés** : Emojis 🔑✅❌ pour faciliter le debugging

## ✅ Checklist de Déploiement

- [ ] Règles Firestore publiées dans Firebase Console
- [ ] Application recompilée avec `flutter clean && flutter pub get`
- [ ] Ancienne version désinstallée de l'appareil de test
- [ ] Nouvelle version installée
- [ ] Test Google Sign-In effectué avec succès
- [ ] Document utilisateur créé dans Firestore
- [ ] Logs vérifiés (pas d'erreurs PERMISSION_DENIED)
- [ ] Test avec connexion internet faible (timeouts fonctionnent)

## 🎯 Résultat Attendu

Après déploiement, le flux Google Sign-In devrait être :

1. ✅ Utilisateur clique sur "Sign in with Google"
2. ✅ Popup/écran Google Sign-In s'affiche
3. ✅ Utilisateur sélectionne son compte
4. ✅ Authentification Firebase réussit
5. ✅ L'app détecte que le document n'existe pas
6. ✅ Redirection vers la page de sélection pays/type d'utilisateur
7. ✅ Utilisateur remplit les informations
8. ✅ Document créé dans Firestore
9. ✅ Redirection vers la page d'approbation en attente (PendingApprovalPage)

**Aucune erreur `PERMISSION_DENIED` ou `User document not found` ne devrait apparaître.**

