// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...

/// ```
class DefaultFirebaseOptions {
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
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyA0kMFIVW43HV5io8prYTBklngg7MYDcoA',
    appId: '1:385256261372:web:f3c9cbf2610683bf727979',
    messagingSenderId: '385256261372',
    projectId: 'pushnotification-9410f',
    authDomain: 'pushnotification-9410f.firebaseapp.com',
    storageBucket: 'pushnotification-9410f.appspot.com',
    measurementId: 'G-B12JF3BFPY',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDFgPQwLn0uTCbchFlxMBTSx7VNLrXRUEU',
    appId: '1:385256261372:android:56708a9e6eecc109727979',
    messagingSenderId: '385256261372',
    projectId: 'pushnotification-9410f',
    storageBucket: 'pushnotification-9410f.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyC1-6R5w5q5DwxdpCpDrfWqHWj7-8g6Byk',
    appId: '1:385256261372:ios:bc0ee82823618938727979',
    messagingSenderId: '385256261372',
    projectId: 'pushnotification-9410f',
    storageBucket: 'pushnotification-9410f.appspot.com',
    iosBundleId: 'com.example.notification',
  );
}
