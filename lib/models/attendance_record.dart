enum AttendanceStatus {
  present,
  absent;

  String get databaseValue => name;
}

class AttendanceRecord {
  const AttendanceRecord({
    required this.studentKey,
    required this.fullName,
    required this.status,
  });

  factory AttendanceRecord.fromRealtimeDatabase({
    required String studentKey,
    required Map<dynamic, dynamic> data,
  }) {
    final value = data['attendance']?.toString().toLowerCase();
    return AttendanceRecord(
      studentKey: studentKey,
      fullName: data['full_name'] as String? ?? 'Unnamed student',
      status: value == 'absent'
          ? AttendanceStatus.absent
          : AttendanceStatus.present,
    );
  }

  final String studentKey;
  final String fullName;
  final AttendanceStatus status;
}
