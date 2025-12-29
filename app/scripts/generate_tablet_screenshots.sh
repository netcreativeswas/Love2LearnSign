#!/bin/bash

# Script pour générer des captures d'écran de tablette 10 pouces pour Google Play Console
# Usage: ./scripts/generate_tablet_screenshots.sh

set -e

# Couleurs pour les messages
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Configuration
SCREENSHOT_DIR="screenshots/tablet_10inch"
TABLET_DEVICE="tablet_10inch"  # Nom de votre émulateur de tablette
RESOLUTION="1920x1200"

echo -e "${GREEN}📱 Script de génération de captures d'écran pour tablette 10 pouces${NC}"
echo ""

# Vérifier si adb est disponible
if ! command -v adb &> /dev/null; then
    echo -e "${RED}❌ Erreur: adb n'est pas installé ou n'est pas dans le PATH${NC}"
    echo "   Installez Android SDK Platform Tools"
    exit 1
fi

# Vérifier si un appareil est connecté
DEVICES=$(adb devices | grep -v "List" | grep "device" | wc -l)
if [ "$DEVICES" -eq 0 ]; then
    echo -e "${YELLOW}⚠️  Aucun appareil/émulateur détecté${NC}"
    echo ""
    echo "Options:"
    echo "1. Démarrez un émulateur de tablette depuis Android Studio"
    echo "2. Connectez une tablette physique via USB"
    echo ""
    echo "Pour créer un émulateur de tablette 10 pouces:"
    echo "  - Ouvrez Android Studio"
    echo "  - AVD Manager → Create Virtual Device"
    echo "  - Sélectionnez 'Tablet' → 'Pixel Tablet' ou 'Nexus 10'"
    echo "  - Résolution: 1920x1200 (10 pouces)"
    echo "  - API Level: Android 11+"
    echo ""
    read -p "Appuyez sur Entrée une fois l'émulateur démarré..."
    DEVICES=$(adb devices | grep -v "List" | grep "device" | wc -l)
    if [ "$DEVICES" -eq 0 ]; then
        echo -e "${RED}❌ Aucun appareil détecté. Arrêt du script.${NC}"
        exit 1
    fi
fi

echo -e "${GREEN}✅ Appareil détecté${NC}"
echo ""

# Créer le dossier de destination
mkdir -p "$SCREENSHOT_DIR"

# Vérifier la résolution de l'écran
SCREEN_SIZE=$(adb shell wm size | awk '{print $3}')
echo "Résolution de l'écran: $SCREEN_SIZE"
echo "Résolution requise: $RESOLUTION"
echo ""

# Fonction pour prendre une capture d'écran
take_screenshot() {
    local name=$1
    local filename="${SCREENSHOT_DIR}/${name}.png"
    
    echo -e "${YELLOW}📸 Capture: $name${NC}"
    
    # Prendre la capture d'écran
    adb shell screencap -p /sdcard/screenshot_${name}.png
    
    # Télécharger la capture
    adb pull /sdcard/screenshot_${name}.png "$filename"
    
    # Supprimer la capture de l'appareil
    adb shell rm /sdcard/screenshot_${name}.png
    
    if [ -f "$filename" ]; then
        echo -e "${GREEN}   ✅ Sauvegardé: $filename${NC}"
    else
        echo -e "${RED}   ❌ Erreur lors de la capture${NC}"
    fi
    echo ""
}

# Instructions pour l'utilisateur
echo -e "${YELLOW}📋 Instructions:${NC}"
echo "1. Assurez-vous que l'app est lancée sur l'émulateur/tablette"
echo "2. Naviguez vers chaque page que vous voulez capturer"
echo "3. Appuyez sur Entrée pour prendre la capture"
echo ""
echo "Pages recommandées à capturer:"
echo "  - Page d'accueil (Home)"
echo "  - Dictionnaire (Dictionary)"
echo "  - Quiz/Flashcards (Game)"
echo "  - Visualisation vidéo (Video Viewer)"
echo "  - Paramètres (Settings)"
echo ""
read -p "Appuyez sur Entrée pour commencer..."

# Prendre les captures d'écran
echo ""
echo -e "${GREEN}🎬 Début des captures...${NC}"
echo ""

# Capture 1: Page d'accueil
read -p "Naviguez vers la page d'accueil, puis appuyez sur Entrée..."
take_screenshot "01_home"

# Capture 2: Dictionnaire
read -p "Naviguez vers le dictionnaire, puis appuyez sur Entrée..."
take_screenshot "02_dictionary"

# Capture 3: Recherche dans le dictionnaire
read -p "Effectuez une recherche dans le dictionnaire, puis appuyez sur Entrée..."
take_screenshot "03_dictionary_search"

# Capture 4: Visualisation vidéo
read -p "Ouvrez une vidéo de signe, puis appuyez sur Entrée..."
take_screenshot "04_video_viewer"

# Capture 5: Quiz/Flashcards
read -p "Naviguez vers les quiz ou flashcards, puis appuyez sur Entrée..."
take_screenshot "05_quiz_flashcards"

# Capture 6: Page de jeu (si disponible)
read -p "Si vous avez une page de jeu active, naviguez-y, puis appuyez sur Entrée..."
take_screenshot "06_game"

# Capture 7: Paramètres
read -p "Naviguez vers les paramètres, puis appuyez sur Entrée..."
take_screenshot "07_settings"

# Capture 8: Favoris (si disponible)
read -p "Si vous avez une page de favoris, naviguez-y, puis appuyez sur Entrée..."
take_screenshot "08_favorites"

echo ""
echo -e "${GREEN}✅ Toutes les captures sont terminées!${NC}"
echo ""
echo "📁 Fichiers sauvegardés dans: $SCREENSHOT_DIR"
echo ""
echo "📋 Prochaines étapes:"
echo "1. Vérifiez les captures d'écran dans le dossier $SCREENSHOT_DIR"
echo "2. Renommez-les si nécessaire"
echo "3. Assurez-vous qu'elles font au moins 1920x1200 pixels"
echo "4. Uploadez-les sur Google Play Console"
echo ""

