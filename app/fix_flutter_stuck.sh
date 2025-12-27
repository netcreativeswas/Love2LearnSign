#!/bin/bash

# Script to fix Flutter stuck issues after project name change
# Run this script if flutter run gets stuck

echo "🧹 Cleaning Flutter project..."

# Navigate to project directory
cd "$(dirname "$0")"

# Kill any stuck Flutter/Dart processes
echo "🔪 Killing stuck Flutter processes..."
pkill -f "flutter_tools" 2>/dev/null || true
pkill -f "dart.*language-server" 2>/dev/null || true

# Clean Flutter build
echo "🧹 Running flutter clean..."
flutter clean

# Remove build directories
echo "🗑️  Removing build directories..."
rm -rf build/
rm -rf .dart_tool/
rm -rf .flutter-plugins
rm -rf .flutter-plugins-dependencies
rm -rf .packages

# Clean Android
echo "🧹 Cleaning Android..."
cd android
./gradlew clean --no-daemon 2>/dev/null || true
rm -rf .gradle/
rm -rf app/build/
cd ..

# Clean iOS
echo "🧹 Cleaning iOS..."
rm -rf ios/Pods/
rm -rf ios/.symlinks/
rm -rf ios/Podfile.lock
rm -rf ios/Flutter/Flutter.framework
rm -rf ios/Flutter/Flutter.podspec
rm -rf ios/build/

# Get dependencies
echo "📦 Getting Flutter dependencies..."
flutter pub get

# Check for devices
echo "📱 Checking for connected devices..."
flutter devices

echo "✅ Cleanup complete! Try running 'flutter run' now."

