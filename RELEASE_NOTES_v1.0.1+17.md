# Release Notes - Version 1.0.1 (Build 17)

## 🎯 What's New

### Search Analytics Improvements
- **Enhanced Daily Usage Heatmap (DUH)**: Improved mobile design with fixed square sizes and horizontal scrolling for better readability
- **Better Mobile Layout**: Fixed overlapping issues on mobile devices - title, buttons, and heatmap squares now display correctly
- **Improved Data Collection**: Search analytics now properly track searches from all users (including guest users) for more accurate insights

### Dashboard Enhancements
- **Search Analytics Page**: Fixed empty state issue - analytics data now loads correctly in the dashboard
- **Heatmap Display**: Month labels now display on a single line (GitHub-style) for cleaner visualization
- **Responsive Design**: Better adaptation between desktop and mobile views

## 🐛 Bug Fixes

- Fixed Firestore rules to allow anonymous search analytics logging
- Fixed timestamp validation in search analytics to prevent data loss
- Improved heatmap rendering on small screens
- Fixed mobile layout where elements were stacking on top of each other

## 🔧 Technical Improvements

- Updated Firestore security rules for better analytics data collection
- Improved error handling in search tracking service
- Enhanced mobile responsiveness for analytics pages

## 📱 Platform Support

- Android: Fully tested and optimized
- Web Dashboard: Enhanced analytics display

---

**Build Number**: 17  
**Version**: 1.0.1  
**Release Date**: January 2025

