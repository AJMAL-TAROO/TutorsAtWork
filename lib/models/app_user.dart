enum UserRole { student, admin }

class AppUser {
  const AppUser({
    required this.key,
    required this.email,
    required this.fullName,
    required this.role,
    this.virtualRoomIds = const [],
    this.approvalStatus,
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
      approvalStatus: data['APRROVAL']?.toString().trim().toLowerCase(),
    );
  }

  final String key;
  final String email;
  final String fullName;
  final UserRole role;
  final List<int> virtualRoomIds;
  final String? approvalStatus;

  bool get isAccessRestricted =>
      role == UserRole.admin &&
      (approvalStatus == 'payment' || approvalStatus == 'pending');

  AppUser copyWith({
    String? key,
    String? email,
    String? fullName,
    UserRole? role,
    List<int>? virtualRoomIds,
    String? approvalStatus,
  }) {
    return AppUser(
      key: key ?? this.key,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      virtualRoomIds: virtualRoomIds ?? this.virtualRoomIds,
      approvalStatus: approvalStatus ?? this.approvalStatus,
    );
  }

  AppUser withApprovalStatus(String? value) {
    return AppUser(
      key: key,
      email: email,
      fullName: fullName,
      role: role,
      virtualRoomIds: virtualRoomIds,
      approvalStatus: value,
    );
  }
}
