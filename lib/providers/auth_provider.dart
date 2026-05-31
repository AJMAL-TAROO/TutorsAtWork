import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_user.dart';
import '../services/auth_service.dart';
import '../services/session_service.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return RealtimeDatabaseAuthService();
});

final initialUserProvider = Provider<AppUser?>((ref) => null);

final sessionServiceProvider = Provider<SessionService>((ref) {
  return SessionService();
});

final currentUserProvider = NotifierProvider<CurrentUserNotifier, AppUser?>(
  CurrentUserNotifier.new,
);

class CurrentUserNotifier extends Notifier<AppUser?> {
  @override
  AppUser? build() => ref.watch(initialUserProvider);

  Future<void> setUser(AppUser user) async {
    state = user;
    await ref.read(sessionServiceProvider).saveUser(user);
  }

  Future<void> clear() async {
    state = null;
    await ref.read(sessionServiceProvider).clearUser();
  }

  Future<void> updateVirtualRoomIds(List<int> virtualRoomIds) async {
    final user = state;
    if (user == null) {
      return;
    }
    final updatedUser = user.copyWith(virtualRoomIds: virtualRoomIds);
    state = updatedUser;
    await ref.read(sessionServiceProvider).saveUser(updatedUser);
  }
}
