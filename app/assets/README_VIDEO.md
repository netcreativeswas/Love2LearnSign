# Intro Video Setup

## To fix the onboarding video issue:

1. **Add a video file** to this `assets/` folder:
   - Format: MP4, WebM, or MOV
   - Recommended: `intro_video.mp4`
   - Size: Keep under 50MB for app performance

2. **Update `pubspec.yaml`** to include the video:
   ```yaml
   flutter:
     assets:
       - assets/
       - assets/intro_video.mp4  # Add this line
   ```

3. **Create Firestore document** `meta/intro` with:
   ```json
   {
     "enabled": true,
     "videoUrl": "assets/intro_video.mp4"
   }
   ```

4. **Alternative**: Use a network URL instead of local file:
   ```json
   {
     "enabled": true,
     "videoUrl": "https://your-domain.com/intro_video.mp4"
   }
   ```

## Current Status:
- ✅ SplashGate navigation working
- ✅ OnboardingVideoScreen displaying
- ❌ No video file found
- ❌ Firestore document empty
