import 'package:firebase_core/firebase_core.dart';

import 'app_config.dart';
import 'firebase_options.dart';

class FirebaseBootstrap {
  const FirebaseBootstrap._();

  static Future<void> maybeInitialize() async {
    if (!AppConfig.enableFirebase || Firebase.apps.isNotEmpty) {
      return;
    }

    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
}
