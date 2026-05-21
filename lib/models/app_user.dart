enum UserRole { student, admin }

class AppUser {
  const AppUser({
    required this.key,
    required this.email,
    required this.fullName,
    required this.role,
    this.virtualRoomIds = const [],
  });

  factory AppUser.fromRealtimeDatabase({
    required String key,
    required UserRole role,
    required Map<dynamic, dynamic> data,
  }) {
    final virtualRooms = (data['VIRTUAL_ROOMS'] as String? ?? '')
        .split(',')
        .map((room) => int.tryParse(room.trim()))
        .whereType<int>()
        .toList();

    return AppUser(
      key: key,
      email: data['EMAIL'] as String? ?? '',
      fullName: data['FULL_NAME'] as String? ?? '',
      role: role,
      virtualRoomIds: virtualRooms,
    );
  }

  final String key;
  final String email;
  final String fullName;
  final UserRole role;
  final List<int> virtualRoomIds;
}
