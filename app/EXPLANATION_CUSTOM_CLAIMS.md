run# Explication : Custom Claims et Règles Firestore

## 🔐 Comment fonctionnent les Custom Claims ?

### 1. **Custom Claims = Données dans le Token JWT**

Quand un utilisateur se connecte à Firebase Auth, il reçoit un **token JWT** (JSON Web Token). Ce token contient :
- L'UID de l'utilisateur
- L'email
- Les **Custom Claims** (rôles, permissions, etc.)

### 2. **Comment les Custom Claims sont définies ?**

Les Custom Claims sont définies par une **Cloud Function** (`updateUserRoles`) qui :
1. Écoute les changements dans Firestore (`users/{userId}`)
2. Quand les rôles changent, elle appelle `auth.setCustomUserClaims(uid, { roles: [...] })`
3. Les Custom Claims sont stockées dans Firebase Auth (pas dans Firestore)

### 3. **Comment les règles Firestore les vérifient ?**

Dans `firestore.rules`, la fonction `isAdmin()` vérifie :
```javascript
request.auth.token.roles is list && 'admin' in request.auth.token.roles
```

Cela lit les Custom Claims directement depuis le **token JWT** de l'utilisateur.

## ⚠️ Le Problème Actuel

### Pourquoi ça ne marche pas ?

1. **Les Custom Claims ne sont pas dans le token** : Même après avoir rafraîchi le token, les Custom Claims ne sont pas présentes
2. **Le fallback ne fonctionne pas** : Le fallback cherche un document avec l'ID = UID, mais vos documents utilisent le format `[displayName]__[UID]`
3. **La Cloud Function ne s'exécute peut-être pas** : La Cloud Function ne se déclenche que si les rôles changent, mais elle devrait maintenant se déclencher même si les rôles n'ont pas changé

## 📝 La Collection `roleLogs`

La collection `roleLogs` n'est **PAS le problème**. C'est juste un journal (log) pour tracer les changements de rôles :
- Elle enregistre qui a changé quoi et quand
- Elle est utilisée pour l'audit et le débogage
- Elle n'affecte pas les permissions

Les règles pour `roleLogs` sont simples : tous les utilisateurs authentifiés peuvent lire/écrire (les admins filtrent côté client).

## 🔧 Solution

Le problème principal est que les **Custom Claims ne sont pas définies** pour vos comptes admin. Il faut :

1. **Vérifier que la Cloud Function s'exécute** : Vérifiez les logs dans Firebase Console
2. **Définir manuellement les Custom Claims** : Utiliser un script ou Firebase Console
3. **Améliorer le code** : Ajouter plus de logs et de vérifications

