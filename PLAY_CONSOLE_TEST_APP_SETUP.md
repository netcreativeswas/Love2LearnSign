# Google Play Console - Test App Setup Guide

This guide will walk you through creating a new test app in Google Play Console for testing purposes.

## Prerequisites

- Google Play Console account with developer access
- Your app's package name: `com.love2learnsign.app` (or use a different one for testing like `com.love2learnsign.app.test`)
- App name: "Love to Learn Sign" (or "Love to Learn Sign - Test" for testing)

---

## Step 1: Create App

### 1.1 Navigate to Create App
1. Go to [Google Play Console](https://play.google.com/console)
2. Click **"Create app"** button (top right or in the dashboard)

### 1.2 Fill in App Details

**App name:**
- Enter: `Love to Learn Sign - Test` (or just `Love to Learn Sign` if you prefer)
- **Note:** App name must be 14-30 characters. "Love to Learn Sign" is 20 characters ✓
- This is how your app will appear on Google Play

**Default language:**
- Select: **English (United Kingdom) – en-GB** ✓
- This is already correctly selected

**App or game:**
- Select: **App** ✓
- (You can change this later in Store settings if needed)

**Free or paid:**
- Select: **Free** ✓
- **Important:** Once published as free, you cannot change to paid later
- Your app uses in-app purchases, so "Free" is correct (the app itself is free)

### 1.3 Declarations

**Developer Programme Policies:**
- ☑ Check the box: **"Confirm that app meets the Developer Programme Policies"**
- Read the policies if you haven't already
- Make sure your app complies with all policies

**US export laws:**
- ☑ Check the box: **"Accept US export laws"**
- This is required for all apps

### 1.4 Create App
- Click **"Create app"** button
- Wait for the app to be created (this may take a few moments)

---

## Step 2: App Access (if prompted)

After creating the app, you may be asked about app access:
- **Internal testing:** Only you and testers you add
- **Closed testing:** Limited group of testers
- **Open testing:** Anyone can join
- **Production:** Public release

For testing purposes, select **"Internal testing"** or **"Closed testing"**.

---

## Step 3: Complete App Setup

After creation, you'll need to complete several sections:

### 3.1 App Content

Navigate to: **Policy → App content**

Complete these sections:
- **Privacy Policy:** Required
  - Add your privacy policy URL (e.g., `https://love2learnsign.com/privacy-policy`)
  - Or upload a privacy policy document
- **Data Safety:** Required
  - Declare what data your app collects
  - Your app uses Firebase, so you'll need to declare:
    - User authentication data
    - App activity/interactions
    - Device or other IDs (for ads)
    - Location (if applicable)
- **Target audience and content:** Required
  - Select appropriate age rating
  - Answer content rating questionnaire

### 3.2 Store Listing

Navigate to: **Store presence → Main store listing**

Required fields:
- **App name:** "Love to Learn Sign - Test" (or your chosen name)
- **Short description:** 80 characters max
  - Example: "Learn sign language with interactive videos and games"
- **Full description:** 4000 characters max
  - Describe your app's features, benefits, etc.
- **App icon:** 512x512 PNG (no transparency)
- **Feature graphic:** 1024x500 PNG
- **Screenshots:** At least 2 required
  - Phone: 16:9 or 9:16 aspect ratio
  - Tablet (if applicable): 16:9 or 9:16 aspect ratio

### 3.3 App Bundle/APK Upload

Navigate to: **Release → Testing** (or **Production**)

**Important:** Before uploading, you need to:

1. **Update package name (if creating separate test app):**
   - If you want a separate test app, change the package name in:
     - `app/android/app/build.gradle` → `applicationId`
     - `app/android/app/src/main/AndroidManifest.xml` → `package`
   - Example: `com.love2learnsign.app.test`

2. **Build your app bundle:**
   ```bash
   cd app
   flutter build appbundle --release
   ```
   - Output: `build/app/outputs/bundle/release/app-release.aab`

3. **Upload the AAB:**
   - Go to **Release → Testing → Internal testing** (or your chosen track)
   - Click **"Create new release"**
   - Upload your `.aab` file
   - Add release notes
   - Review and roll out

### 3.4 App Signing

Google Play will handle app signing automatically:
- First upload: Google generates a signing key
- You can also upload your own key if you have one
- Your existing key in `key.properties` is for local signing

---

## Step 4: Complete Required Sections

Before you can publish (even to testing), complete these required sections:

### ✅ Required Sections Checklist:

- [ ] **App access** - Set up testing tracks
- [ ] **Store listing** - Complete all required fields
- [ ] **App content:**
  - [ ] Privacy Policy
  - [ ] Data Safety
  - [ ] Target audience and content
- [ ] **Pricing and distribution:**
  - [ ] Set as Free
  - [ ] Select countries/regions
- [ ] **App bundle/APK** - Upload at least one release

---

## Step 5: Testing Track Setup

### Internal Testing Track (Recommended for initial testing)

1. Go to **Release → Testing → Internal testing**
2. Click **"Create new release"**
3. Upload your AAB file
4. Add release notes (e.g., "Initial test release")
5. Click **"Save"** (not "Review release" yet)
6. Go to **Testers** tab
7. Add testers by email or create a Google Group
8. Share the opt-in link with testers

### Closed Testing Track

Similar to internal, but:
- Can have up to 100 testers
- More structured testing phases
- Better for beta testing

---

## Step 6: Firebase Configuration (if needed)

If this is a separate test app with a different package name:

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Add a new Android app with the test package name
3. Download `google-services.json`
4. Replace `app/android/app/google-services.json`
5. Update Firebase configuration in your Flutter app

---

## Step 7: Review and Publish

1. Go to **Release → Testing → [Your Track]**
2. Click **"Review release"**
3. Fix any issues that appear
4. Once all checks pass, click **"Start rollout to Internal testing"** (or your chosen track)

---

## Important Notes

### Package Name
- **If using the same package name:** You cannot have two apps with the same package name in Play Console
- **For a test app:** Use a different package name like `com.love2learnsign.app.test`
- **To change package name:** Update it in `build.gradle` and `AndroidManifest.xml`

### App Name
- Must be unique on Google Play
- If "Love to Learn Sign" is taken, use "Love to Learn Sign - Test" or add your developer name

### Version Code
- Each upload must have a higher version code than the previous
- Current version: `1.0.1+23` (version code is 23)
- For test app, start fresh or use a different numbering scheme

### AdMob App ID
- If using a different package name, create a new AdMob app
- Update the AdMob App ID in `AndroidManifest.xml`

---

## Quick Reference

**App Details:**
- **App name:** Love to Learn Sign - Test
- **Package name:** com.love2learnsign.app.test (if separate) OR com.love2learnsign.app (if replacing)
- **Type:** App
- **Pricing:** Free
- **Default language:** English (United Kingdom) - en-GB

**Required Files:**
- App icon: 512x512 PNG
- Feature graphic: 1024x500 PNG
- Screenshots: At least 2 (phone), optional (tablet)
- Privacy Policy: URL or document
- App Bundle: `.aab` file

**Key URLs:**
- Play Console: https://play.google.com/console
- Firebase Console: https://console.firebase.google.com
- AdMob: https://apps.admob.com

---

## Troubleshooting

### "Package name already exists"
- Solution: Use a different package name for the test app
- Or delete the existing app (if it's not published)

### "App name already taken"
- Solution: Add "- Test" suffix or your developer name

### "Missing required sections"
- Check the checklist above
- Complete all sections marked as required

### "Upload failed"
- Ensure your AAB is signed correctly
- Check version code is higher than previous (if updating)
- Verify package name matches Play Console

---

## Next Steps After Setup

1. Upload your first release to internal testing
2. Add testers and share opt-in link
3. Test the app thoroughly
4. Monitor crash reports and analytics
5. Iterate based on feedback
6. When ready, promote to closed testing or production

---

**Last Updated:** Based on current Play Console interface (2025)
**App Version:** 1.0.1+23
**Package:** com.love2learnsign.app

