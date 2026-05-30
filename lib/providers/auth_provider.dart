import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_user.dart';
import '../services/auth_service.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return RealtimeDatabaseAuthService();
});

final currentUserProvider = NotifierProvider<CurrentUserNotifier, AppUser?>(
  CurrentUserNotifier.new,
);

class CurrentUserNotifier extends Notifier<AppUser?> {
  @override
  AppUser? build() => null;

  void setUser(AppUser user) {
    state = user;
  }

  void clear() {
    state = null;
  }

  void updateVirtualRoomIds(List<int> virtualRoomIds) {
    final user = state;
    if (user == null) {
      return;
    }
    state = user.copyWith(virtualRoomIds: virtualRoomIds);
  }
}
