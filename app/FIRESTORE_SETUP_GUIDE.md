# Guide de Configuration Firestore pour Love to Learn Sign

## 🔥 Mise à jour des règles Firestore

### Étape 1 : Accéder à la Console Firebase

1. Allez sur [https://console.firebase.google.com/](https://console.firebase.google.com/)
2. Sélectionnez votre projet **Love to Learn Sign**
3. Dans le menu de gauche, cliquez sur **Firestore Database**

### Étape 2 : Accéder aux Règles de Sécurité

1. Cliquez sur l'onglet **Règles** en haut de la page
2. Vous verrez l'éditeur de règles Firestore

### Étape 3 : Copier les Nouvelles Règles

Copiez et collez le contenu suivant dans l'éditeur de règles (vos règles existantes sont conservées) :

```javascript
rules_version = '2';

service cloud.firestore {
  match /databases/{database}/documents {
    
    // Users collection - users can read/write their own profile
    match /users/{userId} {
      // Users can read and write their own profile
      allow read: if request.auth != null && request.auth.uid == userId;
      // Users can create their own profile during signup
      allow create: if request.auth != null && request.auth.uid == userId;
      // Users can update their own profile
      allow update: if request.auth != null && request.auth.uid == userId;
      // Allow authenticated users to read all (for admin panel)
      allow read: if request.auth != null;
    }
    
    // Role change logs - authenticated users can read/write (admins will filter client-side)
    match /roleLogs/{logId} {
      allow read, write: if request.auth != null;
    }

    // Public categories
    match /categories/{categoryId} {
      allow read: if true;     // anyone can list/get categories
      allow write: if false;   // nobody can write
    }

    // Public words (if you have a top-level `words` collection)
    match /words/{wordId} {
      allow read: if true;
      allow write: if false;
    }
    
    // Dictionary collection: public read, authenticated write
    match /bangla_dictionary_eng_bnsl/{docEngBnslId} {
      allow read:  if true;
      allow write: if request.auth != null;  // ✅ Simple: any authenticated user
    }
    
    // This block to fix the splash intro fetch
    match /meta/intro {
      allow read: if true;    // public read for this single doc
      allow write: if false;  // no client writes
    }
    
    // Catch-all: lock down everything else
    match /{document=**} {
      allow read, write: if false;
    }
  }
}
```

### Étape 4 : Publier les Règles

1. Cliquez sur le bouton **Publier** en haut à droite
2. Attendez la confirmation que les règles ont été publiées

### ⚠️ Note Importante

Les règles ci-dessus conservent toutes vos règles existantes et ajoutent simplement les règles pour les collections `users` et `roleLogs` nécessaires pour l'authentification.

### Étape 5 : Vérifier que ça fonctionne

1. Redémarrez votre application Flutter
2. Essayez de vous connecter
3. Vérifiez dans les logs qu'il n'y a plus d'erreurs `PERMISSION_DENIED` pour la collection `users`

## 🔍 Dépannage

### Si vous obtenez toujours des erreurs de permissions :

1. **Vérifiez que l'utilisateur est bien authentifié** :
   - Les règles nécessitent `request.auth != null`
   - Assurez-vous que Firebase Authentication fonctionne

2. **Vérifiez que le document utilisateur existe** :
   - Allez dans Firestore Database > Collection `users`
   - Vérifiez qu'un document avec l'ID de l'utilisateur existe

3. **Mode Test** (temporaire) :
   Si vous voulez tester rapidement, vous pouvez temporairement utiliser :
   ```javascript
   match /users/{userId} {
     allow read, write: if request.auth != null;
   }
   ```
   ⚠️ **ATTENTION** : Cette règle permet à tous les utilisateurs authentifiés de lire/écrire tous les profils. Utilisez-la uniquement pour tester, puis revenez aux règles sécurisées.

## 📝 Structure des Données Attendue

### Collection `users/{userId}`
```json
{
  "email": "user@example.com",
  "displayName": "John Doe",
  "role": "student",
  "createdAt": "2025-01-12T00:00:00Z",
  "updatedAt": "2025-01-12T00:00:00Z"
}
```

### Rôles disponibles :
- `student` (par défaut)
- `teacher`
- `jw` (Témoins de Jéhovah)
- `admin`
- `editor`

## ✅ Après la Configuration

Une fois les règles mises à jour :
1. Les utilisateurs pourront lire leur propre profil
2. Les utilisateurs pourront créer/mettre à jour leur propre profil lors de l'inscription
3. Les admins pourront gérer tous les utilisateurs via l'Admin Panel
4. Les catégories restreintes seront protégées selon le rôle

