# Release Notes — v1.0.0+6

## 🎯 What's New

### iOS Subscriptions
- **In-App Purchase Support**: Full iOS subscription verification and management
- **App Store Server Integration**: Automatic subscription status updates via App Store Server Notifications v2
- **Tenant-Specific Subscriptions**: Each tenant can have their own subscription products (monthly/yearly)
- **Seamless Premium Access**: Premium status automatically syncs across devices after purchase

### Dashboard Improvements
- **Video Upload Fix**: Tenant admins and editors can now successfully upload videos to Firebase Storage
- **Better Error Handling**: Clear error messages when uploads fail, preventing misleading "success" messages
- **Storage Permissions**: Fixed Storage rules to properly recognize tenant admin and editor roles

## 🐛 Bug Fixes

### Dictionary
- **Sort Preference Persistence**: Dictionary sort order (English/Bangoli) and ascending/descending preference now persists after app restart
- **Per-Tenant Preferences**: Sort preferences are saved separately for each tenant

### Games Page
- **Faster UI Loading**: Free session tokens and "Watch Ad" button now appear immediately without delay
- **Cached Data Display**: Premium status and session tokens use cached values for instant UI updates
- **iOS Alignment**: AppBar titles are now left-aligned on iOS (matching Android and other pages)

### iOS-Specific
- **AppBar Alignment**: Fixed centered titles on Games page to match other pages
- **Storage Upload Support**: Video uploads now work correctly for tenant admins and editors on iOS

## 🔧 Technical Improvements

### Security & Permissions
- **Firestore Rules**: Updated to correctly evaluate tenant roles (`tenantadmin`, `tenant_admin`, `editor`)
- **Storage Rules**: Enhanced to accept `application/octet-stream` content type for video uploads (web compatibility)
- **Tenant Membership Checks**: Improved reliability using `firestore.exists()` for tenant membership verification

### Performance
- **Cached Premium Status**: Premium status is cached locally for 5 minutes, reducing Firestore reads
- **Cached Session Tokens**: Session token balances are cached for faster UI updates
- **Optimized Future Builders**: Pre-created futures prevent unnecessary rebuilds on Games page

### Code Quality
- **Removed Debug Instrumentation**: Cleaned up all temporary debugging code
- **Better Error Messages**: More descriptive error messages for upload failures

## 📱 Platform Support

- **Android**: Fully tested and optimized
- **iOS**: Subscriptions, uploads, and UI alignment fixes
- **Web Dashboard**: Video upload functionality restored for tenant admins/editors

---

**Build Number**: 6  
**Version**: 1.0.0  
**Release Date**: January 2025

