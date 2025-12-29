# Guide pour remplir les informations de collecte de données sur Play Console

Ce guide vous aide à remplir correctement le formulaire de déclaration de collecte de données sur Google Play Console pour votre application **Love to Learn Sign**.

## Vue d'ensemble

Votre application collecte et partage les données suivantes avec des services tiers (Firebase/Google et AdMob). Voici comment remplir chaque section :

---

## 📧 **Email address (Adresse e-mail)**

### Is this data collected, shared or both?
✅ **Collected** ✅ **Shared**

### Is this data processed ephemerally?
❌ **No, this collected data is not processed ephemerally**
- L'adresse e-mail est stockée de manière permanente dans Firebase Authentication pour l'authentification des utilisateurs

### Is this data required for your app, or can users choose whether it's collected?
⚠️ **Users can choose whether this data is collected**
- Les utilisateurs peuvent utiliser l'app en mode invité sans créer de compte
- L'adresse e-mail n'est requise que pour créer un compte (optionnel)

---

## 📱 **Device or other IDs (Identifiants d'appareil)**

### Is this data collected, shared or both?
✅ **Collected** ✅ **Shared**

### Is this data processed ephemerally?
❌ **No, this collected data is not processed ephemerally**
- Les identifiants d'appareil (Advertising ID, Device ID) sont utilisés par AdMob et Firebase
- Ces identifiants sont stockés et utilisés pour la personnalisation des publicités et l'analytique

### Is this data required for your app, or can users choose whether it's collected?
⚠️ **Users can choose whether this data is collected**
- Les utilisateurs peuvent réinitialiser leur Advertising ID dans les paramètres de leur appareil
- Les utilisateurs premium n'ont pas de publicités, donc moins de collecte d'identifiants pour la publicité

---

## 🔍 **App activity (Activité de l'application)**

### Is this data collected, shared or both?
✅ **Collected** ✅ **Shared**

**Inclut :**
- Interactions avec l'app (vues vidéo, sessions de quiz, utilisation des fonctionnalités)
- Historique des recherches dans le dictionnaire (anonymisé)
- Compteurs de vues vidéo
- Sessions de jeu (flashcards, quiz)

### Is this data processed ephemerally?
❌ **No, this collected data is not processed ephemerally**
- Les données d'activité sont stockées dans Firebase Firestore pour l'analyse et l'amélioration de l'app

### Is this data required for your app, or can users choose whether it's collected?
⚠️ **Users can choose whether this data is collected**
- Certaines fonctionnalités nécessitent le suivi (comme les compteurs de vues pour les publicités)
- Mais les utilisateurs peuvent supprimer leur compte pour arrêter la collecte

---

## 📊 **App info and performance (Informations et performances de l'app)**

### Is this data collected, shared or both?
✅ **Collected** ✅ **Shared**

**Inclut :**
- Données de crash (erreurs, plantages)
- Données de performance
- Informations sur le système d'exploitation et le modèle d'appareil

### Is this data processed ephemerally?
❌ **No, this collected data is not processed ephemerally**
- Les données de crash sont stockées dans Firebase pour analyse

### Is this data required for your app, or can users choose whether it's collected?
⚠️ **Data collection is required (users can't turn off this data collection)**
- Les données de crash sont essentielles pour corriger les bugs et améliorer la stabilité
- Cependant, notez que Firebase Analytics peut être désactivé par l'utilisateur dans certains cas

---

## 🎯 **Advertising or marketing (Publicité ou marketing)**

### Is this data collected, shared or both?
✅ **Collected** ✅ **Shared**

**Inclut :**
- Données d'interaction avec les publicités (AdMob)
- Advertising ID
- Données de visualisation des publicités

### Is this data processed ephemerally?
❌ **No, this collected data is not processed ephemerally**
- AdMob collecte et stocke ces données pour la personnalisation des publicités

### Is this data required for your app, or can users choose whether this data is collected?
⚠️ **Users can choose whether this data is collected**
- Les utilisateurs premium ne voient pas de publicités
- Les utilisateurs peuvent réinitialiser leur Advertising ID
- Les utilisateurs peuvent choisir de ne pas utiliser les fonctionnalités qui affichent des publicités

---

## 🔐 **Authentication information (Informations d'authentification)**

### Is this data collected, shared or both?
✅ **Collected** ✅ **Shared**

**Inclut :**
- Email address (déjà déclaré séparément)
- User ID (identifiant unique Firebase)
- Statut de vérification de l'email
- Rôles utilisateur (paidUser, admin, editor)

### Is this data processed ephemerally?
❌ **No, this collected data is not processed ephemerally**
- Stocké de manière permanente dans Firebase Authentication

### Is this data required for your app, or can users choose whether it's collected?
⚠️ **Users can choose whether this data is collected**
- L'authentification est optionnelle (mode invité disponible)

---

## 💳 **Financial info (Informations financières)**

### Is this data collected, shared or both?
❌ **NOT Collected by your app**
- Les informations de paiement sont traitées directement par Google Play Store / Apple App Store
- Votre app ne collecte PAS les détails de carte de crédit
- Vous stockez uniquement le statut d'abonnement (actif/inactif) dans Firebase

**Note :** Vous pouvez déclarer que vous ne collectez PAS ces données, car le traitement des paiements est fait par les stores.

---

## 📍 **Location (Localisation)**

### Is this data collected, shared or both?
❌ **NOT Collected**
- Votre app ne collecte pas de données de localisation GPS

---

## 👤 **Personal info (Informations personnelles)**

### Is this data collected, shared or both?
✅ **Collected** ✅ **Shared** (partiellement)

**Inclut :**
- Nom d'affichage (optionnel)
- Statut démographique optionnel (hearing person / hearing impaired)
- Notes optionnelles lors de l'inscription (texte libre)

### Is this data processed ephemerally?
❌ **No, this collected data is not processed ephemerally**
- Stocké dans Firebase Firestore

### Is this data required for your app, or can users choose whether it's collected?
⚠️ **Users can choose whether this data is collected**
- Toutes ces informations sont optionnelles

---

## 🔍 **Search history (Historique de recherche)**

### Is this data collected, shared or both?
✅ **Collected** (mais **NOT Shared** avec des tiers externes)

**Important :** Les recherches sont anonymisées :
- Texte de requête sanitized
- Timestamp
- Catégorie
- Nombre de résultats
- Flag found/missing
- Session ID anonyme (pas d'email ou User ID)

### Is this data processed ephemerally?
❌ **No, this collected data is not processed ephemerally**
- Stocké dans Firebase Firestore pour analyse

### Is this data required for your app, or can users choose whether it's collected?
⚠️ **Users can choose whether this data is collected**
- Les utilisateurs peuvent choisir de ne pas utiliser la fonctionnalité de recherche

---

## 📝 **User content (Contenu utilisateur)**

### Is this data collected, shared or both?
✅ **Collected** (mais **NOT Shared** avec des tiers)

**Inclut :**
- Favoris (mots et signes sauvegardés)
- Historique de quiz
- Préférences de quiz
- Préférences de notification

### Is this data processed ephemerally?
❌ **No, this collected data is not processed ephemerally**
- Stocké localement et/ou dans Firebase Firestore

### Is this data required for your app, or can users choose whether it's collected?
⚠️ **Users can choose whether this data is collected**
- Les utilisateurs peuvent supprimer leurs favoris et leur historique

---

## 📹 **Videos (Vidéos)**

### Is this data collected, shared or both?
✅ **Collected** (mais principalement en cache local)

**Note :** Les vidéos sont :
- Streamées depuis Firebase Storage
- Mises en cache localement pour la visualisation hors ligne
- Aucune donnée personnelle n'est transmise pendant le streaming

### Is this data processed ephemerally?
⚠️ **Partiellement** - Les vidéos sont mises en cache localement, mais le streaming est temporaire

### Is this data required for your app, or can users choose whether it's collected?
⚠️ **Data collection is required (users can't turn off this data collection)**
- Le streaming vidéo est une fonctionnalité principale de l'app

---

## 🔔 **Messages (Messages)**

### Is this data collected, shared or both?
✅ **Collected** ✅ **Shared**

**Inclut :**
- Notifications push (Firebase Cloud Messaging)
- Préférences de notification

### Is this data processed ephemerally?
❌ **No, this collected data is not processed ephemerally**
- Les tokens de notification sont stockés dans Firebase

### Is this data required for your app, or can users choose whether it's collected?
⚠️ **Users can choose whether this data is collected**
- Les utilisateurs peuvent désactiver les notifications dans les paramètres de l'appareil

---

## 📋 **Résumé des services tiers**

### Services qui collectent/partagent des données :

1. **Google Firebase**
   - Firebase Authentication (email, User ID)
   - Firestore Database (préférences, données d'utilisation, analytics)
   - Firebase Cloud Messaging (notifications)
   - Firebase Storage (vidéos)
   - Firebase Analytics (si activé)

2. **Google AdMob**
   - Données publicitaires
   - Advertising ID
   - Interactions avec les publicités

3. **Google Play Store / Apple App Store**
   - Traitement des paiements (pas de collecte directe par votre app)

---

## ⚠️ **Points importants à retenir**

1. **Mode invité** : Les utilisateurs peuvent utiliser l'app sans compte, donc beaucoup de données sont optionnelles
2. **Utilisateurs premium** : N'ont pas de publicités, donc moins de collecte de données publicitaires
3. **Anonymisation** : Les recherches sont anonymisées (pas d'email/User ID)
4. **Paiements** : Traités par les stores, votre app ne collecte pas les détails de carte

---

## 📞 **Besoin d'aide ?**

Si vous avez des questions spécifiques sur le formulaire Play Console, consultez :
- [Documentation Google Play Console](https://support.google.com/googleplay/android-developer/answer/10787469)
- Votre politique de confidentialité : `/app/PRIVACY_POLICY_UPDATED.md`

