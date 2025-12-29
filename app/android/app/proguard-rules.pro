
# Flutter wrapper rules
-keep class io.flutter.** { *; }
-dontwarn io.flutter.**
-keep class io.flutter.plugins.** { *; }

# Keep classes needed for reflection
-keep class com.google.firebase.** { *; }

# Firebase Messaging
-keep class com.google.firebase.messaging.** { *; }
-dontwarn com.google.firebase.messaging.**

# Firebase Firestore
-keep class com.google.firebase.firestore.** { *; }
-dontwarn com.google.firebase.firestore.**

# Firebase Installations
-keep class com.google.firebase.installations.** { *; }
-dontwarn com.google.firebase.installations.**

# Prevent obfuscation of model classes (adjust the package name accordingly if needed)
-keep class com.love2learnsign.app.model.** { *; }

# Keep all annotations
-keepattributes *Annotation*

# Keep classes used in JSON serialization (e.g., if using Gson or other libraries)
-keep class * implements java.io.Serializable { *; }

# Gson (used by Firestore)
-keepattributes Signature
-keep class com.google.gson.** { *; }
-dontwarn com.google.gson.**
-keep class sun.misc.Unsafe { *; }

# Optional: Enable logging for troubleshooting
-dontwarn io.flutter.embedding.**
-dontwarn io.flutter.plugins.**

# Video Player plugin
-keep class io.flutter.plugins.videoplayer.** { *; }
-keep class com.google.android.exoplayer2.** { *; }
-dontwarn com.google.android.exoplayer2.**