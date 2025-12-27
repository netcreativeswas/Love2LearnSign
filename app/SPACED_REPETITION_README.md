# 📚 Système de Répétition Espacée - Love to Learn Sign

## 🎯 Vue d'ensemble

Ce système de répétition espacée intelligent aide les utilisateurs à mémoriser durablement les mots de langue des signes bengalaise appris via les flashcards. Il est conçu pour être évolutif vers un dashboard utilisateur à l'avenir.

## 🏗️ Architecture

### Services
- **`SpacedRepetitionService`** : Service principal gérant la logique de répétition espacée
- **Stockage local** : Utilise `SharedPreferences` pour persister les données utilisateur

### Modèles de données
- **`WordToReview`** : Représente un mot à réviser avec :
  - `wordId` : Identifiant unique du mot
  - `status` : "À revoir" ou "Maîtrisé"
  - `nextReviewDate` : Date de la prochaine révision
  - `reviewCount` : Nombre de fois que le mot a été revu
  - `lastReviewed` : Date de la dernière révision

## 🔄 Fonctionnalités

### 1. Fin de session flashcard
- **Page de fin de session** : `FlashcardSessionEndPage`
- **Choix du statut** : L'utilisateur peut marquer chaque mot comme :
  - ✅ "Maîtrisé" → Le mot n'est plus à réviser
  - 🔁 "À revoir" → Le mot est ajouté à la boîte de révision

### 2. Planification des révisions
- **Fréquences disponibles** :
  - 1 jour
  - 3 jours
  - 7 jours
  - 14 jours
  - 30 jours
- **Calcul automatique** : La prochaine date de révision est calculée automatiquement

### 3. Section "À réviser" sur la page d'accueil
- **Affichage conditionnel** : Visible seulement s'il y a des mots à réviser aujourd'hui
- **Message motivant** : "📚 Tu as X mots à revoir aujourd'hui"
- **Bouton d'action** : "📖 Revoir maintenant" qui lance une session flashcard

### 4. Intégration dans GameMaster
- **Container B dynamique** : Affiche différents contenus selon qu'il y ait des mots à réviser ou non
- **Si des mots à réviser** :
  - Titre : "📚 Tu as X mots à revoir aujourd'hui"
  - Bouton "📚 Revoir les mots" (primaire)
  - Bouton "🎲 Nouvelle session" (secondaire)
- **Si aucun mot à réviser** :
  - Message : "Choisis un jeu" (comportement par défaut)

## 🧹 Gestion automatique

### Nettoyage des anciens mots
- **Suppression automatique** : Les mots non révisés depuis plus de 31 jours sont supprimés
- **Exécution** : Au démarrage de l'app via `main.dart`
- **Pas d'archivage manuel** : Conçu pour être simple et automatique

## 🔐 Préparation à l'avenir

### Évolutivité
- **Logique métier séparée** : Le service est indépendant du stockage
- **Structure de données claire** : Facilement migrable vers une base de données serveur
- **Synchronisation future** : Conçu pour supporter la synchronisation local/serveur

### Fonctionnalités futures possibles
- Dashboard utilisateur avec statistiques
- Système de comptes et authentification
- Version premium avec options avancées
- Synchronisation multi-appareils

## 📱 Utilisation

### 1. Lancer une session flashcard
- Via la page d'accueil : Section "À réviser" → "📖 Revoir maintenant"
- Via GameMaster : Bouton "📚 Revoir les mots" ou "🎲 Nouvelle session"

### 2. Terminer une session
- À la fin de la session, l'utilisateur est redirigé vers `FlashcardSessionEndPage`
- Choisir le statut de chaque mot (Maîtrisé/À revoir)
- Pour les mots "À revoir", choisir la fréquence de révision
- Sauvegarder et retourner à la page principale

### 3. Suivi des révisions
- Les mots à réviser apparaissent automatiquement sur la page d'accueil
- La section "À réviser" s'affiche seulement quand il y a des mots à réviser aujourd'hui

## 🛠️ Développement

### Fichiers principaux
- `lib/services/spaced_repetition_service.dart` : Service principal
- `lib/flashcard_session_end_page.dart` : Page de fin de session
- `lib/home_page.dart` : Section "À réviser" sur la page d'accueil
- `lib/game_master.dart` : Intégration dans GameMaster
- `lib/main.dart` : Initialisation et nettoyage automatique

### Dépendances
- `shared_preferences` : Stockage local des données
- `provider` : Gestion d'état (déjà présent dans le projet)

## 🎨 Interface utilisateur

### Design
- **Style cohérent** : Utilise le système de thème existant
- **Couleurs sémantiques** : Vert pour "Maîtrisé", orange pour "À revoir"
- **Icônes expressives** : 📚, 📖, 🎲, ✅, 🔁
- **Responsive** : S'adapte aux différentes tailles d'écran

### Expérience utilisateur
- **Pas de mini-révision** : L'utilisateur peut choisir quand réviser
- **Pas de badges** : Focus sur l'apprentissage, pas sur la gamification
- **Feedback clair** : Messages explicites sur le nombre de mots à réviser
- **Navigation intuitive** : Boutons clairs et actions logiques

## 🚀 Déploiement

### Compilation
```bash
flutter pub get
flutter analyze
flutter build apk --debug
```

### Tests
- Vérifier que la section "À réviser" s'affiche correctement
- Tester le flux complet : session → fin de session → sauvegarde
- Vérifier que les mots apparaissent à la bonne date de révision

## 📝 Notes techniques

### Performance
- **Stockage local** : Pas de latence réseau
- **Nettoyage automatique** : Évite l'accumulation de données obsolètes
- **Singleton pattern** : Une seule instance du service en mémoire

### Sécurité
- **Données locales** : Pas de transmission de données personnelles
- **Validation** : Vérification des données avant sauvegarde
- **Gestion d'erreurs** : Fallbacks en cas de problème de stockage

### Maintenance
- **Code modulaire** : Facile à maintenir et étendre
- **Documentation** : Commentaires clairs dans le code
- **Tests** : Structure prête pour l'ajout de tests unitaires
