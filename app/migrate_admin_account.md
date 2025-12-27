# Guide de Migration du Compte Admin

## Problème
Après la mise à jour du système de rôles, les anciens comptes utilisent le format `role: "admin"` (string) au lieu du nouveau format `roles: ["admin"]` (array).

## Solution Rapide : Mettre à jour manuellement dans Firestore

### Option 1 : Via Firebase Console (Recommandé)

1. Allez dans [Firebase Console](https://console.firebase.google.com/)
2. Sélectionnez votre projet `love-to-learn-sign`
3. Allez dans **Firestore Database**
4. Trouvez la collection `users`
5. Trouvez votre document utilisateur (par email ou UID)
6. Modifiez le document pour :
   - **Supprimer** le champ `role: "admin"` (si présent)
   - **Ajouter** le champ `roles` avec la valeur : `["admin"]` (array)
   - **Ajouter** le champ `status` avec la valeur : `"approved"`
   - **Ajouter** le champ `approved` avec la valeur : `true`

### Option 2 : Via Script Node.js

Créez un fichier `migrate_admin.js` dans le dossier `functions/` :

```javascript
const admin = require('firebase-admin');
admin.initializeApp();

const db = admin.firestore();

async function migrateAdminAccount(userEmail) {
  try {
    // Trouver l'utilisateur par email
    const usersSnapshot = await db.collection('users')
      .where('email', '==', userEmail)
      .get();
    
    if (usersSnapshot.empty) {
      console.log('Aucun utilisateur trouvé avec cet email');
      return;
    }
    
    const batch = db.batch();
    
    usersSnapshot.forEach(doc => {
      const data = doc.data();
      const updates = {};
      
      // Si l'utilisateur a l'ancien format 'role'
      if (data.role && !data.roles) {
        updates.roles = [data.role];
        updates.status = 'approved';
        updates.approved = true;
        console.log(`Migration de ${userEmail}: role "${data.role}" -> roles ["${data.role}"]`);
      }
      
      if (Object.keys(updates).length > 0) {
        batch.update(doc.ref, updates);
      }
    });
    
    await batch.commit();
    console.log('Migration terminée avec succès!');
  } catch (error) {
    console.error('Erreur lors de la migration:', error);
  }
}

// Utilisation: node migrate_admin.js votre-email@example.com
const userEmail = process.argv[2];
if (!userEmail) {
  console.log('Usage: node migrate_admin.js email@example.com');
  process.exit(1);
}

migrateAdminAccount(userEmail).then(() => process.exit(0));
```

Puis exécutez :
```bash
cd functions
node migrate_admin.js jeanluccarbonel@gmail.com
```

### Option 3 : Migration automatique (déjà implémentée)

Le code a été mis à jour pour migrer automatiquement les anciens comptes lors de la connexion. Cependant, pour forcer la migration immédiatement :

1. **Déconnectez-vous** de l'application
2. **Reconnectez-vous** avec votre compte admin
3. Le système devrait automatiquement migrer votre compte

## Vérification

Après la migration, vérifiez que votre document utilisateur dans Firestore contient :
- `roles: ["admin"]` (array)
- `status: "approved"`
- `approved: true`

## Note

Le code a été mis à jour pour supporter les deux formats (ancien et nouveau) et migrer automatiquement lors de la connexion. Cependant, si vous voulez accéder immédiatement à l'Admin Panel, utilisez l'Option 1 (Firebase Console) pour mettre à jour manuellement votre compte.

