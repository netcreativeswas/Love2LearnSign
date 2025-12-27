# 📘 Guide Complet : Installation Premium & Google Ads

## ✅ Vérification de l'Implémentation

### Fichiers Créés/Modifiés

#### ✅ Services Créés
- `lib/services/subscription_service.dart` - Gestion des achats in-app
- `lib/services/premium_service.dart` - Gestion de l'état premium
- `lib/services/ad_service.dart` - Gestion des publicités (déjà existant, vérifié)

#### ✅ Pages UI Créées
- `lib/pages/premium_explanation_page.dart` - Page d'explication Premium
- `lib/pages/premium_settings_page.dart` - Page de paramètres Premium
- `lib/widgets/monthly_premium_reminder.dart` - Widget de rappel mensuel

#### ✅ Fichiers Modifiés
- `lib/main.dart` - Initialisation des services
- `lib/video_viewer_page.dart` - Intégration des publicités interstitielles
- `lib/game_master.dart` - Intégration des publicités récompensées
- `lib/settings_page.dart` - Section Premium ajoutée
- `pubspec.yaml` - Dépendances ajoutées

### 🔍 Problèmes Identifiés et Corrigés

1. ✅ **Import manquant** - `ProductDetails` ajouté dans les pages premium
2. ✅ **Getters null-safe** - `monthlyProduct` et `yearlyProduct` corrigés
3. ✅ **Bug rewarded ad** - Correction du callback asynchrone
4. ✅ **Cohérence des rôles** - Utilisation de `paidUser` (camelCase) partout

---

## 🚀 Marche à Suivre Étape par Étape

### ÉTAPE 1 : Installation des Dépendances

```bash
cd "/Users/jl/love_to_learn_sign (20251008)"
flutter pub get
```

**Vérification :**
- ✅ `google_mobile_ads: ^5.1.0` installé
- ✅ `in_app_purchase: ^3.2.0` installé

---

### ÉTAPE 2 : Configuration Google AdMob

#### 2.1 Créer un Compte AdMob

1. Aller sur https://admob.google.com
2. Se connecter avec votre compte Google
3. Créer un nouveau compte AdMob (si vous n'en avez pas)

#### 2.2 Créer une Application dans AdMob

1. Dans AdMob, cliquer sur **"Apps"** → **"Add app"**
2. Sélectionner votre plateforme :
   - **Android** : Entrer le nom du package (ex: `com.lovetolearnsign.app`)
   - **iOS** : Entrer le Bundle ID (ex: `com.lovetolearnsign.app`)
3. Copier l'**App ID** généré (format: `ca-app-pub-XXXXXXXXXXXXXXXX~XXXXXXXXXX`)

#### 2.3 Créer les Unités de Publicité

**Pour Android :**
1. Dans votre app AdMob, cliquer sur **"Ad units"** → **"Add ad unit"**
2. Créer une unité **Interstitial** :
   - Nom : "Interstitial Dictionary"
   - Type : Interstitial
   - Copier l'**Ad Unit ID** (format: `ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX`)
3. Créer une unité **Rewarded** :
   - Nom : "Rewarded Games"
   - Type : Rewarded
   - Copier l'**Ad Unit ID**

**Pour iOS :**
1. Répéter les mêmes étapes pour iOS
2. Noter les Ad Unit IDs iOS séparément

#### 2.4 Mettre à Jour le Code

**Fichier : `lib/services/ad_service.dart`**

```dart
// Lignes 24-26 - Remplacer avec vos IDs de production
static const String _prodInterstitialAdUnitId = 'VOTRE_ID_INTERSTITIAL_ANDROID';
static const String _prodRewardedAdUnitId = 'VOTRE_ID_REWARDED_ANDROID';
```

**Fichier : `android/app/src/main/AndroidManifest.xml`**

```xml
<!-- Ligne ~60 - Remplacer avec votre App ID Android -->
<meta-data
    android:name="com.google.android.gms.ads.APPLICATION_ID"
    android:value="ca-app-pub-XXXXXXXXXXXXXXXX~XXXXXXXXXX"/>
```

**Fichier : `ios/Runner/Info.plist`**

```xml
<!-- Ajouter votre App ID iOS -->
<key>GADApplicationIdentifier</key>
<string>ca-app-pub-XXXXXXXXXXXXXXXX~XXXXXXXXXX</string>
```

---

### ÉTAPE 3 : Configuration Google Play Console (Android)

#### 3.1 Activer les Achats In-App

1. Aller sur https://play.google.com/console
2. Sélectionner votre application
3. Aller dans **"Monétisation"** → **"Produits"** → **"Abonnements"**
4. Cliquer sur **"Créer un abonnement"**

#### 3.2 Créer l'Abonnement Mensuel

1. **ID du produit** : `premium_monthly` (doit correspondre au code)
2. **Nom** : "Premium Monthly"
3. **Description** : "Abonnement mensuel Premium"
4. **Prix** : Définir votre prix mensuel
5. **Période de facturation** : 1 mois
6. **Période d'essai gratuite** (optionnel) : 0 jours
7. Cliquer sur **"Enregistrer"**

#### 3.3 Créer l'Abonnement Annuel

1. **ID du produit** : `premium_yearly`
2. **Nom** : "Premium Yearly"
3. **Description** : "Abonnement annuel Premium - Meilleure valeur"
4. **Prix** : Définir votre prix annuel
5. **Période de facturation** : 12 mois
6. Cliquer sur **"Enregistrer"**

#### 3.4 Activer les Tests

1. Aller dans **"Configuration"** → **"Accès aux licences"**
2. Ajouter les adresses email des comptes de test
3. Ces comptes pourront tester les achats sans payer

---

### ÉTAPE 4 : Configuration App Store Connect (iOS)

#### 4.1 Créer les Abonnements

1. Aller sur https://appstoreconnect.apple.com
2. Sélectionner votre application
3. Aller dans **"Fonctionnalités"** → **"Abonnements"**
4. Cliquer sur **"Créer un groupe d'abonnements"**

#### 4.2 Créer le Groupe Premium

1. **Référence du groupe** : "Premium"
2. **Nom** : "Premium Subscriptions"
3. Cliquer sur **"Créer"**

#### 4.3 Créer l'Abonnement Mensuel

1. Dans le groupe, cliquer sur **"Créer un abonnement"**
2. **ID du produit** : `premium_monthly`
3. **Nom** : "Premium Monthly"
4. **Durée** : 1 mois
5. **Prix** : Définir votre prix
6. Cliquer sur **"Créer"**

#### 4.4 Créer l'Abonnement Annuel

1. **ID du produit** : `premium_yearly`
2. **Nom** : "Premium Yearly"
3. **Durée** : 12 mois
4. **Prix** : Définir votre prix
5. Cliquer sur **"Créer"**

#### 4.5 Configurer les Métadonnées

Pour chaque abonnement :
1. Ajouter une description
2. Ajouter des captures d'écran (optionnel)
3. Soumettre pour révision

---

### ÉTAPE 5 : Mettre à Jour les Product IDs dans le Code

**Fichier : `lib/services/subscription_service.dart`**

```dart
// Lignes 19-29 - Vérifier que les IDs correspondent à ceux créés
static const String _monthlyProductId = 'premium_monthly';
static const String _yearlyProductId = 'premium_yearly';

// Si vos IDs Android/iOS sont différents, les modifier ici
static const String _monthlyProductIdAndroid = 'premium_monthly';
static const String _yearlyProductIdAndroid = 'premium_yearly';
static const String _monthlyProductIdIOS = 'premium_monthly';
static const String _yearlyProductIdIOS = 'premium_yearly';
```

---

### ÉTAPE 6 : Configuration Firebase Firestore

#### 6.1 Structure de la Collection `users`

Votre collection `users` doit avoir cette structure :

```javascript
users/{userId} {
  roles: ["freeUser", "paidUser"], // Array de rôles
  subscription_type: "monthly" | "yearly",
  subscription_start_date: Timestamp,
  subscription_renewal_date: Timestamp,
  subscription_platform: "android" | "ios",
  last_payment_date: Timestamp,
  subscription_active: boolean
}
```

#### 6.2 Règles de Sécurité Firestore

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      // L'utilisateur peut lire ses propres données
      allow read: if request.auth != null && request.auth.uid == userId;
      // L'utilisateur peut écrire ses propres données (pour les mises à jour de subscription)
      allow write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

---

### ÉTAPE 7 : Tests Locaux

#### 7.1 Tester les Publicités (Mode Debug)

Les IDs de test sont déjà configurés. Pour tester :

```bash
flutter run
```

**Tests à effectuer :**
1. ✅ Regarder 8 vidéos → Publicité interstitielle doit apparaître
2. ✅ Jouer 2 sessions Flashcard → Dialog de publicité récompensée
3. ✅ Jouer 2 sessions Quiz → Dialog de publicité récompensée
4. ✅ Vérifier que les utilisateurs `paidUser` ne voient pas de publicités

#### 7.2 Tester les Achats In-App (Sandbox)

**Android :**
1. Créer un compte de test dans Google Play Console
2. Se connecter avec ce compte sur l'appareil
3. Tester l'achat (ne sera pas facturé)

**iOS :**
1. Créer un compte Sandbox dans App Store Connect
2. Se connecter avec ce compte dans Réglages → App Store
3. Tester l'achat (ne sera pas facturé)

---

### ÉTAPE 8 : Build de Production

#### 8.1 Android

```bash
flutter build apk --release
# ou
flutter build appbundle --release
```

**Vérifications avant publication :**
- ✅ AdMob App ID configuré dans AndroidManifest.xml
- ✅ Ad Unit IDs de production dans ad_service.dart
- ✅ Product IDs corrects dans subscription_service.dart
- ✅ Compte de test configuré dans Play Console

#### 8.2 iOS

```bash
flutter build ios --release
```

**Vérifications avant publication :**
- ✅ AdMob App ID configuré dans Info.plist
- ✅ Ad Unit IDs de production dans ad_service.dart
- ✅ Product IDs corrects dans subscription_service.dart
- ✅ Abonnements créés et approuvés dans App Store Connect

---

### ÉTAPE 9 : Déploiement

#### 9.1 Android - Google Play

1. Uploader le fichier `.aab` dans Play Console
2. Remplir les informations de la version
3. Dans **"Monétisation"**, vérifier que les abonnements sont liés
4. Soumettre pour révision

#### 9.2 iOS - App Store

1. Archiver l'application dans Xcode
2. Uploader vers App Store Connect
3. Créer une nouvelle version dans App Store Connect
4. Vérifier que les abonnements sont configurés
5. Soumettre pour révision

---

## 🔧 Dépannage

### Problème : Les publicités ne s'affichent pas

**Solutions :**
1. Vérifier que l'App ID AdMob est correct dans AndroidManifest.xml/Info.plist
2. Vérifier que les Ad Unit IDs sont corrects
3. Vérifier la connexion internet
4. Attendre quelques minutes après la création des unités (propagation)

### Problème : Les achats ne fonctionnent pas

**Solutions :**
1. Vérifier que les Product IDs correspondent exactement
2. Vérifier que les abonnements sont actifs dans Play Console/App Store Connect
3. Vérifier que vous utilisez un compte de test (pour les tests)
4. Vérifier les logs : `flutter logs` pour voir les erreurs

### Problème : Le rôle `paidUser` n'est pas attribué

**Solutions :**
1. Vérifier que Firestore est accessible
2. Vérifier les règles de sécurité Firestore
3. Vérifier que `subscription_active` est mis à `true` après l'achat
4. Vérifier que `AuthProvider` recharge les rôles après l'achat

---

## 📋 Checklist Finale

### Configuration AdMob
- [ ] Compte AdMob créé
- [ ] Application créée dans AdMob
- [ ] Unités Interstitial créées (Android + iOS)
- [ ] Unités Rewarded créées (Android + iOS)
- [ ] App IDs configurés dans AndroidManifest.xml et Info.plist
- [ ] Ad Unit IDs de production dans ad_service.dart

### Configuration In-App Purchases
- [ ] Abonnements mensuels créés (Play Console + App Store Connect)
- [ ] Abonnements annuels créés (Play Console + App Store Connect)
- [ ] Product IDs vérifiés dans subscription_service.dart
- [ ] Comptes de test configurés

### Configuration Firebase
- [ ] Structure Firestore vérifiée
- [ ] Règles de sécurité configurées
- [ ] Test de lecture/écriture effectué

### Tests
- [ ] Publicités testées en mode debug
- [ ] Achats testés en sandbox
- [ ] Rôles `paidUser` vérifiés
- [ ] Limites de sessions vérifiées
- [ ] Rappel mensuel testé

### Build Production
- [ ] Build Android créé et testé
- [ ] Build iOS créé et testé
- [ ] Tous les IDs de production configurés
- [ ] Prêt pour publication

---

## 📞 Support

Si vous rencontrez des problèmes :

1. **Logs Flutter** : `flutter logs` pour voir les erreurs
2. **Console AdMob** : Vérifier les statistiques et erreurs
3. **Play Console / App Store Connect** : Vérifier l'état des abonnements
4. **Firebase Console** : Vérifier les données Firestore

---

## 🎉 Félicitations !

Une fois toutes ces étapes complétées, votre système Premium et Google Ads sera opérationnel !

**Temps estimé total :** 2-4 heures (selon votre familiarité avec les plateformes)

