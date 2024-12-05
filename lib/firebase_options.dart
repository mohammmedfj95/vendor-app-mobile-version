import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'No Web configuration found. Follow Firebase setup guide for Web.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        throw UnsupportedError(
          'No iOS configuration found. Follow Firebase setup guide for iOS.',
        );
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'No macOS configuration found. Follow Firebase setup guide for macOS.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'No Windows configuration found. Follow Firebase setup guide for Windows.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'No Linux configuration found. Follow Firebase setup guide for Linux.',
        );
      default:
        throw UnsupportedError(
          'Unknown platform. Follow Firebase setup guide.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBQIMpOo2iHQNwTDERBGPva8Otzxl9Id5g',
    appId: '1:836146918548:android:0442f4ee5ccb2d725b3081',
    messagingSenderId: '836146918548',
    projectId: 'store-management-ea221',
    storageBucket: 'store-management-ea221.firebasestorage.app',
  );
}
