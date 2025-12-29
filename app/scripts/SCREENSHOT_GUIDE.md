# Guide pour générer des captures d'écran de tablette 10 pouces

Ce guide vous explique comment créer les captures d'écran requises par Google Play Console pour les tablettes 10 pouces.

## 📋 Prérequis

1. **Android Studio** installé
2. **Flutter SDK** installé
3. **Android SDK Platform Tools** (adb) dans le PATH

## 🚀 Méthode 1 : Script automatique (Recommandé)

### Étape 1 : Créer un émulateur de tablette 10 pouces

1. Ouvrez **Android Studio**
2. Allez dans **Tools → Device Manager** (ou **AVD Manager**)
3. Cliquez sur **Create Device**
4. Sélectionnez **Tablet** dans la catégorie
5. Choisissez un modèle :
   - **Pixel Tablet** (recommandé)
   - **Nexus 10**
   - Ou un autre modèle de tablette
6. Cliquez sur **Next**
7. Sélectionnez une image système (API Level 30+ recommandé)
8. Cliquez sur **Next**
9. Vérifiez les paramètres :
   - **Resolution**: 1920x1200 (10 pouces)
   - **Density**: xhdpi ou xxhdpi
10. Cliquez sur **Finish**

### Étape 2 : Démarrer l'émulateur

1. Dans **Device Manager**, cliquez sur le bouton **Play** ▶️ à côté de votre émulateur
2. Attendez que l'émulateur démarre complètement

### Étape 3 : Installer l'app sur l'émulateur

```bash
cd /Users/jl/Love2LearnSign/app
flutter run
```

Ou si vous avez déjà un APK :

```bash
adb install path/to/your/app.apk
```

### Étape 4 : Exécuter le script

```bash
cd /Users/jl/Love2LearnSign/app
chmod +x scripts/generate_tablet_screenshots.sh
./scripts/generate_tablet_screenshots.sh
```

Le script vous guidera pour prendre les captures d'écran de chaque page importante.

## 🎨 Méthode 2 : Captures manuelles

### Option A : Via l'émulateur Android Studio

1. Lancez votre app sur l'émulateur
2. Naviguez vers la page à capturer
3. Dans l'émulateur, cliquez sur l'icône **...** (trois points) dans la barre latérale
4. Cliquez sur **Screenshot** 📸
5. La capture sera sauvegardée dans votre dossier de téléchargements

### Option B : Via adb (ligne de commande)

```bash
# Prendre une capture d'écran
adb shell screencap -p /sdcard/screenshot.png

# Télécharger la capture
adb pull /sdcard/screenshot.png ~/Desktop/screenshot.png

# Supprimer la capture de l'appareil
adb shell rm /sdcard/screenshot.png
```

### Option C : Via Flutter Screenshot

```bash
# Prendre une capture d'écran directement
flutter screenshot
```

## 📸 Pages recommandées à capturer

Pour Google Play Console, capturez au moins 2-8 captures d'écran montrant :

1. **Page d'accueil** - Montre l'interface principale
2. **Dictionnaire** - Montre la fonctionnalité de recherche
3. **Visualisation vidéo** - Montre un signe en action
4. **Quiz/Flashcards** - Montre les fonctionnalités d'apprentissage
5. **Paramètres** - Montre les options disponibles
6. **Favoris** (si disponible) - Montre la gestion des favoris

## ✅ Spécifications requises

- **Résolution minimale**: 1920x1200 pixels
- **Format**: PNG ou JPEG
- **Nombre**: Au moins 2, recommandé 4-8
- **Contenu**: Doit montrer les fonctionnalités principales de l'app

## 🔧 Vérifier la résolution

Pour vérifier la résolution de votre émulateur :

```bash
adb shell wm size
```

Pour changer la résolution si nécessaire :

```bash
adb shell wm size 1920x1200
```

## 📁 Organisation des fichiers

Les captures seront sauvegardées dans :
```
app/screenshots/tablet_10inch/
  ├── 01_home.png
  ├── 02_dictionary.png
  ├── 03_dictionary_search.png
  ├── 04_video_viewer.png
  ├── 05_quiz_flashcards.png
  ├── 06_game.png
  ├── 07_settings.png
  └── 08_favorites.png
```

## 🎯 Astuces

1. **Utilisez le mode paysage** : Les tablettes sont souvent utilisées en mode paysage
2. **Montrez du contenu réel** : Utilisez de vrais mots et signes, pas des placeholders
3. **Assurez-vous que le texte est lisible** : Sur une tablette, le texte doit être clair
4. **Évitez les overlays** : Fermez les menus déroulants avant de capturer
5. **Utilisez un thème cohérent** : Toutes les captures doivent avoir le même style

## 🆘 Dépannage

### L'émulateur est trop lent
- Réduisez la RAM allouée dans les paramètres de l'émulateur
- Utilisez une image système x86_64 au lieu d'ARM

### Les captures sont floues
- Vérifiez que la résolution est bien 1920x1200
- Utilisez PNG au lieu de JPEG pour une meilleure qualité

### L'app ne s'affiche pas correctement
- Vérifiez que l'app supporte les tablettes (responsive design)
- Testez en mode paysage et portrait

## 📚 Ressources

- [Documentation Google Play Console - Screenshots](https://support.google.com/googleplay/android-developer/answer/9866151)
- [Flutter Screenshot Documentation](https://docs.flutter.dev/deployment/android#taking-screenshots-for-the-play-store)

