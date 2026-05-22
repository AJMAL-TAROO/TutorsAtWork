import 'app_config.dart';

class FirebaseBootstrap {
  const FirebaseBootstrap._();

  static Future<void> maybeInitialize() async {
    if (!AppConfig.enableFirebase) return;
  }
}
