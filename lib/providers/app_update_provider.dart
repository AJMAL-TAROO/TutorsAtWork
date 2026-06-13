import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/app_update_service.dart';

final appUpdateServiceProvider = Provider<AppUpdateService>((ref) {
  return AppUpdateService();
});
