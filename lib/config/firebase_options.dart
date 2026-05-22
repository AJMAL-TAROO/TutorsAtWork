import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class DefaultFirebaseOptions {
  const DefaultFirebaseOptions._();

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.macOS:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        throw UnsupportedError('Firebase is not configured for this platform.');
    }
  }

  static const web = FirebaseOptions(
    apiKey: 'AIzaSyCwol-nlbl1YbdAiU88nYFv67pJg2XOo9U',
    authDomain: 'houseoftutors-f398e.firebaseapp.com',
    databaseURL: 'https://houseoftutors-f398e-default-rtdb.firebaseio.com/',
    projectId: 'houseoftutors-f398e',
    storageBucket: 'houseoftutors-f398e.firebasestorage.app',
    messagingSenderId: '1006665226128',
    appId: '1:1006665226128:web:bcf481758d361da3ef8515',
    measurementId: 'G-PEM636J9ZD',
  );

  static const android = FirebaseOptions(
    apiKey: 'AIzaSyCwol-nlbl1YbdAiU88nYFv67pJg2XOo9U',
    appId: '1:1006665226128:web:bcf481758d361da3ef8515',
    messagingSenderId: '1006665226128',
    projectId: 'houseoftutors-f398e',
    databaseURL: 'https://houseoftutors-f398e-default-rtdb.firebaseio.com/',
    storageBucket: 'houseoftutors-f398e.firebasestorage.app',
  );

  static const ios = FirebaseOptions(
    apiKey: 'AIzaSyCwol-nlbl1YbdAiU88nYFv67pJg2XOo9U',
    appId: '1:1006665226128:web:bcf481758d361da3ef8515',
    messagingSenderId: '1006665226128',
    projectId: 'houseoftutors-f398e',
    databaseURL: 'https://houseoftutors-f398e-default-rtdb.firebaseio.com/',
    storageBucket: 'houseoftutors-f398e.firebasestorage.app',
    iosBundleId: 'com.houseoftutors.taw',
  );

  static const windows = FirebaseOptions(
    apiKey: 'AIzaSyCwol-nlbl1YbdAiU88nYFv67pJg2XOo9U',
    appId: '1:1006665226128:web:bcf481758d361da3ef8515',
    messagingSenderId: '1006665226128',
    projectId: 'houseoftutors-f398e',
    databaseURL: 'https://houseoftutors-f398e-default-rtdb.firebaseio.com/',
    storageBucket: 'houseoftutors-f398e.firebasestorage.app',
  );
}
