import '../models/attendance_record.dart';
import 'firebase_database_service.dart';

abstract class AttendanceService {
  Future<Map<String, AttendanceRecord>> attendanceForDate({
    required DateTime date,
    required String adminKey,
    required int classroomId,
  });

  Future<void> saveAttendance({
    required DateTime date,
    required String adminKey,
    required int classroomId,
    required Iterable<AttendanceRecord> records,
  });

  Future<void> deleteAttendance({
    required DateTime date,
    required String adminKey,
    required int classroomId,
  });

  Future<List<AttendanceExportRow>> monthlyAttendance({
    required int year,
    required int month,
    required String adminKey,
    required int classroomId,
    required String classroomTitle,
  });
}

class RealtimeDatabaseAttendanceService implements AttendanceService {
  RealtimeDatabaseAttendanceService({FirebaseDatabaseService? databaseService})
    : _databaseService = databaseService ?? FirebaseDatabaseService();

  final FirebaseDatabaseService _databaseService;

  @override
  Future<Map<String, AttendanceRecord>> attendanceForDate({
    required DateTime date,
    required String adminKey,
    required int classroomId,
  }) async {
    final value = await _databaseService.get(
      _classroomPath(date: date, adminKey: adminKey, classroomId: classroomId),
    );
    return _recordsFromValue(value);
  }

  @override
  Future<void> saveAttendance({
    required DateTime date,
    required String adminKey,
    required int classroomId,
    required Iterable<AttendanceRecord> records,
  }) async {
    final payload = <String, Object>{};
    for (final record in records) {
      payload[record.studentKey] = {
        'full_name': record.fullName,
        'attendance': record.status.databaseValue,
      };
    }

    await _databaseService.set(
      _classroomPath(date: date, adminKey: adminKey, classroomId: classroomId),
      payload,
    );
  }

  @override
  Future<void> deleteAttendance({
    required DateTime date,
    required String adminKey,
    required int classroomId,
  }) async {
    await _databaseService.remove(
      _classroomPath(date: date, adminKey: adminKey, classroomId: classroomId),
    );
  }

  @override
  Future<List<AttendanceExportRow>> monthlyAttendance({
    required int year,
    required int month,
    required String adminKey,
    required int classroomId,
    required String classroomTitle,
  }) async {
    final value = await _databaseService.get(
      'ATTENDANCE/$year/${_twoDigits(month)}',
    );
    final rows = <AttendanceExportRow>[];
    if (value is! Map) {
      return rows;
    }

    final sortedDays = value.keys.map((key) => key.toString()).toList()..sort();
    for (final day in sortedDays) {
      final dayValue = value[day];
      if (dayValue is! Map) {
        continue;
      }
      final adminValue = dayValue[adminKey];
      if (adminValue is! Map) {
        continue;
      }
      final classroomValue = adminValue['CLASSROOM_$classroomId'];
      for (final record in _recordsFromValue(classroomValue).values) {
        rows.add(
          AttendanceExportRow(
            studentKey: record.studentKey,
            studentName: record.fullName,
            date: '$year-${_twoDigits(month)}-$day',
            status: record.status.databaseValue,
            classroomTitle: classroomTitle,
          ),
        );
      }
    }
    return rows;
  }

  Map<String, AttendanceRecord> _recordsFromValue(Object? value) {
    final records = <String, AttendanceRecord>{};
    if (value is! Map) {
      return records;
    }

    for (final entry in value.entries) {
      final data = entry.value;
      if (data is Map) {
        records[entry.key.toString()] = AttendanceRecord.fromRealtimeDatabase(
          studentKey: entry.key.toString(),
          data: data,
        );
      }
    }
    return records;
  }

  String _classroomPath({
    required DateTime date,
    required String adminKey,
    required int classroomId,
  }) {
    return 'ATTENDANCE/${date.year}/${_twoDigits(date.month)}/${_twoDigits(date.day)}/$adminKey/CLASSROOM_$classroomId';
  }

  String _twoDigits(int value) => value.toString().padLeft(2, '0');
}

class AttendanceExportRow {
  const AttendanceExportRow({
    required this.studentKey,
    required this.studentName,
    required this.date,
    required this.status,
    required this.classroomTitle,
  });

  final String studentKey;
  final String studentName;
  final String date;
  final String status;
  final String classroomTitle;
}
