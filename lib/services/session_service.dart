import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_user.dart';

class SessionService {
  static const _currentUserKey = 'current_user';

  Future<AppUser?> loadUser() async {
    final preferences = await SharedPreferences.getInstance();
    final value = preferences.getString(_currentUserKey);
    if (value == null) {
      return null;
    }

    try {
      final data = jsonDecode(value);
      if (data is! Map<String, dynamic>) {
        await clearUser();
        return null;
      }

      final key = data['key']?.toString();
      final email = data['email']?.toString();
      final fullName = data['fullName']?.toString();
      final roleName = data['role']?.toString();
      if (key == null ||
          email == null ||
          fullName == null ||
          roleName == null) {
        await clearUser();
        return null;
      }

      return AppUser(
        key: key,
        email: email,
        fullName: fullName,
        role: UserRole.values.byName(roleName),
        virtualRoomIds: (data['virtualRoomIds'] as List? ?? const [])
            .map((roomId) => int.tryParse(roomId.toString()))
            .whereType<int>()
            .toList(),
      );
    } catch (_) {
      await clearUser();
      return null;
    }
  }

  Future<void> saveUser(AppUser user) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _currentUserKey,
      jsonEncode({
        'key': user.key,
        'email': user.email,
        'fullName': user.fullName,
        'role': user.role.name,
        'virtualRoomIds': user.virtualRoomIds,
      }),
    );
  }

  Future<void> clearUser() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_currentUserKey);
  }
}
