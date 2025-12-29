#!/bin/bash

# Script rapide pour prendre des captures d'écran avec Flutter
# Usage: ./scripts/quick_screenshot.sh [nom_de_la_capture]

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

SCREENSHOT_DIR="screenshots/tablet_10inch"
mkdir -p "$SCREENSHOT_DIR"

if [ -z "$1" ]; then
    TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    FILENAME="${SCREENSHOT_DIR}/screenshot_${TIMESTAMP}.png"
else
    FILENAME="${SCREENSHOT_DIR}/${1}.png"
fi

echo -e "${YELLOW}📸 Prise de capture d'écran...${NC}"

# Utiliser flutter screenshot si disponible, sinon adb
if command -v flutter &> /dev/null; then
    flutter screenshot "$FILENAME"
else
    adb shell screencap -p /sdcard/temp_screenshot.png
    adb pull /sdcard/temp_screenshot.png "$FILENAME"
    adb shell rm /sdcard/temp_screenshot.png
fi

if [ -f "$FILENAME" ]; then
    echo -e "${GREEN}✅ Capture sauvegardée: $FILENAME${NC}"
    
    # Afficher les dimensions de l'image (si ImageMagick est installé)
    if command -v identify &> /dev/null; then
        DIMENSIONS=$(identify -format "%wx%h" "$FILENAME")
        echo "   Dimensions: $DIMENSIONS"
    fi
else
    echo -e "${RED}❌ Erreur lors de la capture${NC}"
    exit 1
fi

