# TestFlight Upload Guide

## ✅ Completed Steps

1. ✅ Updated entitlements to use `production` environment
2. ✅ Built iOS archive (IPA) - Version 1.0.0 (Build 6)
3. ✅ IPA file created at: `app/build/ios/ipa/love_to_learn_sign.ipa` (55MB)

## 📤 Next Steps: Upload to App Store Connect

### Option 1: Using Apple Transporter (Recommended - Easiest)

1. **Download Apple Transporter** (if you don't have it):
   - Open Mac App Store
   - Search for "Transporter"
   - Install it

2. **Upload the IPA**:
   - Open Apple Transporter
   - Drag and drop `app/build/ios/ipa/love_to_learn_sign.ipa` into Transporter
   - Sign in with your Apple Developer account
   - Click "Deliver"
   - Wait for upload to complete (5-10 minutes)

### Option 2: Using Xcode Organizer

1. **Open Xcode Organizer**:
   - Open Xcode
   - Go to **Window → Organizer** (or press `Cmd + Shift + 9`)

2. **If archive is already there**:
   - Find your archive (should be listed)
   - Select it
   - Click **"Distribute App"**
   - Choose **"App Store Connect"**
   - Follow the wizard

3. **If archive is not there**:
   - In Xcode, open `app/ios/Runner.xcworkspace`
   - Select **"Any iOS Device"** as target
   - Go to **Product → Archive**
   - Wait for archive to complete
   - In Organizer, select the archive
   - Click **"Distribute App"**
   - Choose **"App Store Connect"**
   - Follow the wizard

### Option 3: Using Command Line (xcrun altool)

```bash
cd /Users/jl/Love2LearnSign/app
xcrun altool --upload-app \
  --type ios \
  --file build/ios/ipa/love_to_learn_sign.ipa \
  --apiKey YOUR_API_KEY \
  --apiIssuer YOUR_ISSUER_ID
```

(Requires App Store Connect API key setup)

## ⏳ After Upload

1. **Wait for Processing** (10-30 minutes):
   - Go to [App Store Connect](https://appstoreconnect.apple.com)
   - Select your app: **Love to Learn Sign**
   - Go to **TestFlight** tab
   - You'll see your build processing
   - Status will change from "Processing" to "Ready to Test"

2. **Set Up Internal Testing** (Instant access):
   - In TestFlight, go to **"Internal Testing"**
   - Click **"+"** to create a group (e.g., "Internal Testers")
   - Select your build (1.0.0 (6))
   - Click **"Add"**
   - Add testers:
     - Go to **"Users and Access" → "Testers"**
     - Add email addresses of people in your App Store Connect team
     - They'll receive an email invitation

3. **Set Up External Testing** (Optional, requires review):
   - Go to **"External Testing"**
   - Create a group
   - Add your build
   - Fill in required information (What to Test, Description)
   - Submit for **Beta App Review** (first time only, usually quick)
   - Add external testers by email

## 📱 Testers Install Your App

1. Testers receive an email invitation
2. They install **TestFlight** app from App Store (if needed)
3. They open the invitation email and tap **"Start Testing"**
4. TestFlight app opens
5. They tap **"Install"** on your app
6. App installs like a normal app

## ✅ Verification Checklist

- [ ] IPA uploaded to App Store Connect
- [ ] Build processing completed (status: "Ready to Test")
- [ ] Internal testing group created
- [ ] Testers added to group
- [ ] Testers received invitations
- [ ] App Attest working (check Firebase Console → App Check → APIs → Firestore for "Verified" requests)

## 🔍 Troubleshooting

### Build Processing Failed
- Check email from Apple for details
- Common issues: missing icons, invalid provisioning profile, code signing issues

### App Attest Still Not Working
- Wait 24 hours after TestFlight install for App Attest to fully activate
- Check Firebase Console → App Check → Your apps → Love2LearnSign-ios is still "Registered"
- Verify entitlements are set to `production` (already done ✅)

### Testers Can't Install
- Make sure they accepted the email invitation
- Check they have TestFlight app installed
- Verify their device is compatible (iOS 13.0+)

## 📝 Notes

- **Build expires**: TestFlight builds expire after 90 days
- **Multiple builds**: You can upload multiple builds; testers can switch between them
- **Private**: App is NOT publicly visible - only invited testers can access
- **App Attest**: Will work properly in TestFlight builds (production environment)

---

**Build Details:**
- Version: 1.0.0
- Build Number: 6
- Bundle ID: com.love2learnsign.app
- IPA Location: `app/build/ios/ipa/love_to_learn_sign.ipa`
- Size: 55MB

