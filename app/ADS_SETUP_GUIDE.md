# Ads System Setup Guide

## ✅ Implementation Complete

The interstitial and rewarded ads system has been fully implemented. Here's what to do next:

## 📋 Next Steps

### 1. **Test with Test Ads (Current Setup)**
The app is currently configured to use Google's test ad unit IDs. You can test immediately:

- **Interstitial Ads**: Watch 8 dictionary videos → ad should appear
- **Rewarded Ads**: Use 2 flashcard/quiz sessions → ad dialog should appear
- **Role Testing**: Users with `paidUser` or `admin` roles should see NO ads

### 2. **Set Up AdMob Account** (For Production)

1. Go to https://admob.google.com
2. Sign in with your Google account
3. Create a new app (if you don't have one)
4. Get your **App ID** (format: `ca-app-pub-XXXXXXXXXXXXXXXX~XXXXXXXXXX`)

### 3. **Create Ad Units**

In your AdMob dashboard:
- Create an **Interstitial** ad unit
- Create a **Rewarded** ad unit
- Copy both ad unit IDs (format: `ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX`)

### 4. **Update Production Ad Unit IDs**

Edit `lib/services/ad_service.dart`:
- Replace `_prodInterstitialAdUnitId` (line 25) with your interstitial ad unit ID
- Replace `_prodRewardedAdUnitId` (line 26) with your rewarded ad unit ID

### 5. **Update AdMob App ID**

**Android** (`android/app/src/main/AndroidManifest.xml`):
- Replace the test App ID in the `<meta-data>` tag with your production App ID

**iOS** (`ios/Runner/Info.plist`):
- Replace the test App ID in `GADApplicationIdentifier` with your production App ID

### 6. **Test Production Build**

Build a release version and test:
```bash
flutter build apk --release  # Android
flutter build ios --release   # iOS
```

## 🎯 Features Implemented

### Interstitial Ads
- ✅ Shows after every 8 video views
- ✅ Tracks views globally across all video pages
- ✅ Resets counter after ad is shown
- ✅ Skips for `paidUser` and `admin` roles

### Rewarded Ads
- ✅ Flashcard Game: 2 free sessions/month, then rewarded ad unlocks 3 more
- ✅ Quiz Game: 2 free sessions/month, then rewarded ad unlocks 3 more
- ✅ Monthly reset logic
- ✅ Skips limits for `paidUser` and `admin` roles

### Session Tracking
- ✅ Persistent storage in Firestore
- ✅ Monthly counters reset automatically
- ✅ Guest users can play but aren't tracked

## 🔍 Testing Checklist

- [ ] Test interstitial ads appear after 8 video views
- [ ] Test rewarded ads unlock sessions correctly
- [ ] Test session limits work (2 free/month)
- [ ] Test `paidUser` role bypasses all ads and limits
- [ ] Test `admin` role bypasses all ads and limits
- [ ] Test monthly reset (wait for new month or manually change date)
- [ ] Test error handling (no internet, ad fails to load)

## 📝 Important Notes

1. **Test Ads**: Currently using Google's test ad unit IDs - these work for testing but don't generate revenue
2. **Production Ads**: Replace test IDs before releasing to production
3. **AdMob Policies**: Make sure your app complies with AdMob policies
4. **User Experience**: Ads are designed to be non-disruptive (shown between actions, not during gameplay)

## 🐛 Troubleshooting

If ads don't appear:
1. Check console logs for ad loading errors
2. Verify AdMob App ID is correctly configured
3. Ensure you're using test ad unit IDs for testing
4. Check internet connection
5. Verify user doesn't have `paidUser` or `admin` role (they won't see ads)

## 📚 Documentation

- [Google Mobile Ads Flutter Plugin](https://pub.dev/packages/google_mobile_ads)
- [AdMob Documentation](https://support.google.com/admob)

