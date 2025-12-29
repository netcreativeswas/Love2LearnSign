# Référence rapide - Formulaire Play Console

## 📋 Réponses rapides pour chaque type de données

### ✅ **Email address**
- **Collected** : ✅ Oui
- **Shared** : ✅ Oui (Firebase)
- **Ephemeral** : ❌ Non
- **Required** : ⚠️ Optionnel (mode invité disponible)

---

### ✅ **Device or other IDs**
- **Collected** : ✅ Oui
- **Shared** : ✅ Oui (Firebase, AdMob)
- **Ephemeral** : ❌ Non
- **Required** : ⚠️ Optionnel (utilisateurs peuvent réinitialiser Advertising ID)

---

### ✅ **App activity**
- **Collected** : ✅ Oui
- **Shared** : ✅ Oui (Firebase)
- **Ephemeral** : ❌ Non
- **Required** : ⚠️ Optionnel (certaines fonctionnalités nécessitent le suivi)

---

### ✅ **App info and performance**
- **Collected** : ✅ Oui
- **Shared** : ✅ Oui (Firebase Crashlytics)
- **Ephemeral** : ❌ Non
- **Required** : ✅ Oui (essentiel pour corriger les bugs)

---

### ✅ **Advertising or marketing**
- **Collected** : ✅ Oui
- **Shared** : ✅ Oui (AdMob)
- **Ephemeral** : ❌ Non
- **Required** : ⚠️ Optionnel (pas pour les utilisateurs premium)

---

### ✅ **Authentication information**
- **Collected** : ✅ Oui
- **Shared** : ✅ Oui (Firebase Auth)
- **Ephemeral** : ❌ Non
- **Required** : ⚠️ Optionnel (mode invité disponible)

---

### ❌ **Financial info**
- **Collected** : ❌ Non (traité par Google Play Store uniquement)
- **Shared** : ❌ Non

---

### ❌ **Location**
- **Collected** : ❌ Non

---

### ✅ **Personal info**
- **Collected** : ✅ Oui (nom d'affichage, statut démographique optionnel)
- **Shared** : ✅ Oui (Firebase)
- **Ephemeral** : ❌ Non
- **Required** : ⚠️ Optionnel

---

### ✅ **Search history**
- **Collected** : ✅ Oui (anonymisé)
- **Shared** : ⚠️ Non (stocké dans Firebase mais anonymisé, pas partagé avec tiers externes)
- **Ephemeral** : ❌ Non
- **Required** : ⚠️ Optionnel

---

### ✅ **User content**
- **Collected** : ✅ Oui (favoris, historique quiz)
- **Shared** : ⚠️ Non (stocké dans Firebase mais pas partagé avec tiers)
- **Ephemeral** : ❌ Non
- **Required** : ⚠️ Optionnel

---

### ✅ **Videos**
- **Collected** : ✅ Oui (streaming et cache)
- **Shared** : ⚠️ Partiellement (streaming depuis Firebase Storage)
- **Ephemeral** : ⚠️ Partiellement (streaming temporaire, cache local)
- **Required** : ✅ Oui (fonctionnalité principale)

---

### ✅ **Messages**
- **Collected** : ✅ Oui (notifications push)
- **Shared** : ✅ Oui (Firebase Cloud Messaging)
- **Ephemeral** : ❌ Non
- **Required** : ⚠️ Optionnel (utilisateurs peuvent désactiver)

---

## 🔗 Services tiers à déclarer

1. **Google Firebase** (Authentication, Firestore, Analytics, Storage, Messaging)
2. **Google AdMob** (Publicités)
3. **Google Play Store** (Paiements - mais pas de collecte directe par votre app)

---

## 💡 Astuce importante

Pour la plupart des données, choisissez **"Users can choose whether this data is collected"** car :
- Les utilisateurs peuvent utiliser l'app en mode invité
- Les utilisateurs premium n'ont pas de publicités
- Les utilisateurs peuvent supprimer leur compte

Seules les données de **crash/performance** et le **streaming vidéo** sont vraiment requises pour le fonctionnement de l'app.

