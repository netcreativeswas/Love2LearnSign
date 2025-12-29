# Scripts de génération de captures d'écran

Ce dossier contient des scripts pour générer automatiquement les captures d'écran de tablette 10 pouces requises par Google Play Console.

## 📁 Fichiers

- **`generate_tablet_screenshots.sh`** - Script interactif guidé pour prendre plusieurs captures
- **`quick_screenshot.sh`** - Script rapide pour prendre une capture unique
- **`SCREENSHOT_GUIDE.md`** - Guide complet d'utilisation

## 🚀 Utilisation rapide

### Script interactif (recommandé)

```bash
cd /Users/jl/Love2LearnSign/app
./scripts/generate_tablet_screenshots.sh
```

Ce script vous guidera étape par étape pour capturer toutes les pages importantes.

### Script rapide (une capture)

```bash
cd /Users/jl/Love2LearnSign/app
./scripts/quick_screenshot.sh nom_de_la_capture
```

Exemple:
```bash
./scripts/quick_screenshot.sh home_page
```

## 📋 Prérequis

1. Un émulateur de tablette 10 pouces démarré (résolution 1920x1200)
2. L'app installée et lancée sur l'émulateur
3. `adb` dans le PATH (ou Flutter SDK)

## 📸 Pages à capturer

1. Page d'accueil
2. Dictionnaire
3. Recherche dans le dictionnaire
4. Visualisation vidéo
5. Quiz/Flashcards
6. Paramètres
7. Favoris (si disponible)

## 📚 Documentation complète

Voir `SCREENSHOT_GUIDE.md` pour le guide détaillé.

