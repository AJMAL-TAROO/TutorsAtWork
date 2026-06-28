import 'package:firebase_core/firebase_core.dart';

import 'app_config.dart';
import 'firebase_options.dart';

class FirebaseBootstrap {
  const FirebaseBootstrap._();

  static Future<void> maybeInitialize() async {
    if (!AppConfig.enableFirebase) return;
    if (Firebase.apps.isNotEmpty) return;

    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: DefaultFirebaseOptions.apiKey,
        authDomain: DefaultFirebaseOptions.authDomain,
        databaseURL: DefaultFirebaseOptions.databaseURL,
        projectId: DefaultFirebaseOptions.projectId,
        storageBucket: DefaultFirebaseOptions.storageBucket,
        messagingSenderId: DefaultFirebaseOptions.messagingSenderId,
        appId: DefaultFirebaseOptions.appId,
        measurementId: DefaultFirebaseOptions.measurementId,
      ),
    );
  }
}
