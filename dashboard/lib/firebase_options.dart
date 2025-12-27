import 'package:firebase_core/firebase_core.dart'
    show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  /// Default [FirebaseOptions] for the current platform.
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  /// FirebaseOptions for Web
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyD2iaGZTa28Qino57AS7E1bzNTJct7vLD4',
    authDomain: 'love-to-learn-sign.firebaseapp.com',
    projectId: 'love-to-learn-sign',
    storageBucket: 'love-to-learn-sign.firebasestorage.app',
    messagingSenderId: '844270366247',
    appId: '1:844270366247:web:803c57423d08c863436802',
    measurementId: 'G-XPPWJ6MFVW',
  );

  /// FirebaseOptions for Android
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyD2iaGZTa28Qino57AS7E1bzNTJct7vLD4',
    appId: '1:844270366247:web:803c57423d08c863436802',
    messagingSenderId: '844270366247',
    projectId: 'love-to-learn-sign',
    storageBucket: 'love-to-learn-sign.firebasestorage.app',
  );

  /// FirebaseOptions for iOS
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyD2iaGZTa28Qino57AS7E1bzNTJct7vLD4',
    appId: '1:844270366247:web:803c57423d08c863436802',
    messagingSenderId: '844270366247',
    projectId: 'love-to-learn-sign',
    storageBucket: 'love-to-learn-sign.firebasestorage.app',
    iosClientId: 'YOUR_IOS_CLIENT_ID', // from GoogleService-Info.plist
    iosBundleId: 'YOUR_IOS_BUNDLE_ID', // your Xcode bundle ID
  );

  /// FirebaseOptions for macOS
  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyD2iaGZTa28Qino57AS7E1bzNTJct7vLD4',
    appId: '1:844270366247:web:803c57423d08c863436802',
    messagingSenderId: '844270366247',
    projectId: 'love-to-learn-sign',
    storageBucket: 'love-to-learn-sign.firebasestorage.app',
    iosClientId: 'YOUR_IOS_CLIENT_ID', // reuse iOS client ID
    iosBundleId: 'YOUR_MACOS_BUNDLE_ID', // your macOS bundle ID
  );

  /// FirebaseOptions for Windows
  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyD2iaGZTa28Qino57AS7E1bzNTJct7vLD4',
    appId: '1:844270366247:web:803c57423d08c863436802',
    messagingSenderId: '844270366247',
    projectId: 'love-to-learn-sign',
    storageBucket: 'love-to-learn-sign.firebasestorage.app',
  );
}