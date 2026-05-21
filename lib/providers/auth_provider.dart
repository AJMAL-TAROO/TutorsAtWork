import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_user.dart';
import '../services/auth_service.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return const PlaceholderAuthService();
});

final currentUserProvider = StateProvider<AppUser?>((ref) => null);
