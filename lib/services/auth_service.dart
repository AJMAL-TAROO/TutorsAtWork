import '../models/app_user.dart';

abstract class AuthService {
  Future<AppUser?> signIn({
    required String email,
    required String password,
    required UserRole role,
  });
}

class PlaceholderAuthService implements AuthService {
  const PlaceholderAuthService();

  @override
  Future<AppUser?> signIn({
    required String email,
    required String password,
    required UserRole role,
  }) async {
    if (email.trim().isEmpty || password.trim().isEmpty) {
      return null;
    }

    return AppUser(
      key: 'local-preview-user',
      email: email.trim(),
      fullName: role == UserRole.student ? 'Student Preview' : 'Admin Preview',
      role: role,
      virtualRoomIds: const [1001, 1002, 1003],
    );
  }
}
