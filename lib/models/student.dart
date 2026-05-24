class Student {
  const Student({
    required this.key,
    required this.fullName,
    required this.email,
    required this.virtualRoomIds,
  });

  factory Student.fromRealtimeDatabase({
    required String key,
    required Map<dynamic, dynamic> data,
  }) {
    return Student(
      key: key,
      fullName: data['FULL_NAME'] as String? ?? 'Unnamed student',
      email: data['EMAIL'] as String? ?? '',
      virtualRoomIds: (data['VIRTUAL_ROOMS'] as String? ?? '')
          .split(',')
          .map((room) => int.tryParse(room.trim()))
          .whereType<int>()
          .toList(),
    );
  }

  final String key;
  final String fullName;
  final String email;
  final List<int> virtualRoomIds;
}
