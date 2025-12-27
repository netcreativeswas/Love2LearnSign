# Guide : Comment fonctionnent les Custom Claims

## 🔄 Le processus automatique

Quand vous modifiez les rôles d'un utilisateur dans l'Admin Panel, voici ce qui se passe :

### Étape 1 : Modification dans Firestore
```
Admin Panel → Modifie roles: ["admin"] dans /users/{userId}
```

### Étape 2 : Cloud Function se déclenche automatiquement
```
Cloud Function "updateUserRoles" détecte le changement
→ Met à jour les Custom Claims dans Firebase Auth
→ Enregistre le changement dans /roleLogs
```

### Étape 3 : L'utilisateur doit rafraîchir son token
```
L'utilisateur doit se déconnecter/reconnecter
OU utiliser getIdToken(true) pour obtenir le nouveau token avec les Custom Claims
```

---

## ⚠️ Problème actuel : PERMISSION_DENIED

L'erreur `PERMISSION_DENIED` signifie que **les règles Firestore bloquent l'écriture**.

### Pourquoi ?
Les règles Firestore vérifient si vous êtes admin **AVANT** de permettre la modification. Si votre document Firestore n'a pas encore `roles: ["admin"]`, ou si les règles ne sont pas déployées, l'accès est refusé.

---

## ✅ Solution : Déployer les règles Firestore

### Option 1 : Via Firebase Console (Recommandé)

1. **Ouvrez Firebase Console**
   - Allez sur https://console.firebase.google.com
   - Sélectionnez votre projet `love-to-learn-sign`

2. **Accédez aux règles Firestore**
   - Menu gauche → **Firestore Database**
   - Onglet **Rules**

3. **Copiez les règles depuis `firestore.rules`**
   - Ouvrez le fichier `firestore.rules` dans votre éditeur
   - Copiez tout le contenu

4. **Collez dans Firebase Console**
   - Remplacez le contenu actuel par les nouvelles règles
   - Cliquez sur **Publish**

5. **Attendez quelques secondes** pour que les règles se propagent

### Option 2 : Via Firebase CLI

```bash
cd "/Users/jl/love_to_learn_sign (20251008)"
firebase deploy --only firestore:rules
```

---

## 🔍 Vérifier que ça fonctionne

### 1. Vérifiez votre document Firestore
- Firebase Console → Firestore Database → Data
- Collection `users` → Votre document (UID: `iaHtBXRA7zctFdqoVKPYw4gJscm2`)
- Vérifiez que `roles` existe et contient `["admin"]`

### 2. Vérifiez les logs de la Cloud Function
- Firebase Console → Functions
- Cliquez sur `updateUserRoles`
- Onglet **Logs**
- Vous devriez voir : `Updated Custom Claims for user {userId} with roles: ["admin"]`

### 3. Vérifiez les Custom Claims (optionnel)
- Firebase Console → Authentication → Users
- Trouvez votre utilisateur
- Les Custom Claims ne sont pas visibles directement dans la console
- Mais vous pouvez vérifier via les logs de la Cloud Function

### 4. Testez dans l'app
- Déconnectez-vous puis reconnectez-vous
- Essayez de modifier les rôles d'un autre utilisateur
- Ça devrait fonctionner maintenant !

---

## 🛠️ Dépannage

### Si ça ne marche toujours pas :

1. **Vérifiez que la Cloud Function est déployée**
   ```bash
   cd functions
   firebase functions:list
   ```
   Vous devriez voir `updateUserRoles` dans la liste.

2. **Vérifiez les logs de la Cloud Function**
   - Firebase Console → Functions → `updateUserRoles` → Logs
   - Cherchez les erreurs

3. **Vérifiez que votre document Firestore a bien `roles: ["admin"]`**
   - Si ce n'est pas le cas, ajoutez-le manuellement dans Firebase Console

4. **Rafraîchissez votre token dans l'app**
   - Déconnectez-vous complètement
   - Reconnectez-vous
   - Les nouveaux Custom Claims seront chargés

---

## 📝 Résumé

1. ✅ **Déployez les règles Firestore** (le plus important !)
2. ✅ Vérifiez que votre document a `roles: ["admin"]`
3. ✅ Vérifiez que la Cloud Function `updateUserRoles` est déployée
4. ✅ Déconnectez/reconnectez-vous dans l'app
5. ✅ Testez la modification des rôles

Les Custom Claims sont mis à jour **automatiquement** par la Cloud Function quand vous modifiez les rôles dans Firestore. Vous n'avez rien à faire manuellement !

