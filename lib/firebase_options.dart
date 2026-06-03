// Firebase configuration for Food Waste Management
// Project: food-waste-management-549d6
//
// After adding your app in Firebase Console, run:
//   firebase login
//   flutterfire configure --project=food-waste-management-549d6
// Or paste apiKey and appId from Project settings into the placeholders below.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static const String _projectId = 'food-waste-management-549d6';
  static const String _messagingSenderId = '716084398651';
  static const String _storageBucket =
      'food-waste-management-549d6.firebasestorage.app';

  static const String _androidApiKey = 'AIzaSyAGMi8IXh_PRmXLKhuMXzP-wB9YZ_N-GDQ';
  static const String _androidAppId =
      '1:716084398651:android:d9202e3062feffd6152a1e';

  static const String _webApiKey = 'AIzaSyCUhMo0Z7chEEfuLZgzKJXxSxs-nriv8yA';
  static const String _webAppId = '1:716084398651:web:6aaee5c916f8fc6b152a1e';

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not configured for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: _webApiKey,
    appId: _webAppId,
    messagingSenderId: _messagingSenderId,
    projectId: _projectId,
    authDomain: '$_projectId.firebaseapp.com',
    storageBucket: _storageBucket,
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: _androidApiKey,
    appId: _androidAppId,
    messagingSenderId: _messagingSenderId,
    projectId: _projectId,
    storageBucket: _storageBucket,
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: _androidApiKey,
    appId: _androidAppId,
    messagingSenderId: _messagingSenderId,
    projectId: _projectId,
    storageBucket: _storageBucket,
    iosBundleId: 'com.example.myapp',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: _androidApiKey,
    appId: _androidAppId,
    messagingSenderId: _messagingSenderId,
    projectId: _projectId,
    storageBucket: _storageBucket,
    iosBundleId: 'com.example.myapp',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: _webApiKey,
    appId: _webAppId,
    messagingSenderId: _messagingSenderId,
    projectId: _projectId,
    authDomain: '$_projectId.firebaseapp.com',
    storageBucket: _storageBucket,
  );

  static bool get isConfigured {
    if (kIsWeb) {
      return !_webApiKey.startsWith('YOUR_');
    }
    return !_androidApiKey.startsWith('YOUR_');
  }
}
