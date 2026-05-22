import 'firebase_database_service.dart';
import '../models/app_user.dart';

abstract class AuthService {
  Future<AppUser?> signIn({
    required String email,
    required String password,
    required UserRole role,
  });
}

class RealtimeDatabaseAuthService implements AuthService {
  RealtimeDatabaseAuthService({FirebaseDatabaseService? databaseService})
    : _databaseService = databaseService ?? FirebaseDatabaseService();

  final FirebaseDatabaseService _databaseService;

  @override
  Future<AppUser?> signIn({
    required String email,
    required String password,
    required UserRole role,
  }) async {
    final normalizedEmail = email.trim();
    final normalizedPassword = password.trim();

    if (normalizedEmail.isEmpty || normalizedPassword.isEmpty) {
      return null;
    }

    final usersRef = role == UserRole.student
        ? _databaseService.students
        : _databaseService.admins;
    final users = await _databaseService.get(usersRef);

    if (users is! Map) {
      return null;
    }

    for (final entry in users.entries) {
      final data = entry.value;
      if (data is! Map) {
        continue;
      }

      final storedEmail = data['EMAIL']?.toString().trim();
      final storedPassword = data['PASSWORD']?.toString().trim();

      if (storedEmail == normalizedEmail &&
          storedPassword == normalizedPassword) {
        return AppUser.fromRealtimeDatabase(
          key: entry.key.toString(),
          role: role,
          data: data,
        );
      }
    }

    return null;
  }
}
