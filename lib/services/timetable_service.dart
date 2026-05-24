import '../models/timetable_session.dart';
import 'firebase_database_service.dart';

abstract class TimetableService {
  Future<List<TimetableSession>> sessionsForAdmin(String adminKey);

  Stream<List<TimetableSession>> watchSessionsForAdmin(String adminKey);

  Future<void> upsertSession({
    required String adminKey,
    required int day,
    required String timeRange,
    required String classroomTitle,
  });

  Future<void> deleteSession({
    required String adminKey,
    required int day,
    required String timeRange,
  });
}

class RealtimeDatabaseTimetableService implements TimetableService {
  RealtimeDatabaseTimetableService({FirebaseDatabaseService? databaseService})
    : _databaseService = databaseService ?? FirebaseDatabaseService();

  final FirebaseDatabaseService _databaseService;

  @override
  Future<List<TimetableSession>> sessionsForAdmin(String adminKey) async {
    final value = await _databaseService.get(_path(adminKey));
    return _sessionsFromValue(value);
  }

  @override
  Stream<List<TimetableSession>> watchSessionsForAdmin(String adminKey) {
    return _databaseService.watch(_path(adminKey)).map(_sessionsFromValue);
  }

  @override
  Future<void> upsertSession({
    required String adminKey,
    required int day,
    required String timeRange,
    required String classroomTitle,
  }) async {
    await _databaseService.update('TIME_TABLE/$adminKey/VALUE/$day', {
      timeRange: classroomTitle,
    });
  }

  @override
  Future<void> deleteSession({
    required String adminKey,
    required int day,
    required String timeRange,
  }) async {
    await _databaseService.remove('TIME_TABLE/$adminKey/VALUE/$day/$timeRange');
  }

  String _path(String adminKey) => 'TIME_TABLE/$adminKey/VALUE';

  List<TimetableSession> _sessionsFromValue(Object? value) {
    final sessions = <TimetableSession>[];
    if (value is! Map) {
      return sessions;
    }

    for (final dayEntry in value.entries) {
      final day = int.tryParse(dayEntry.key.toString());
      final dayValue = dayEntry.value;
      if (day == null || dayValue is! Map) {
        continue;
      }

      for (final sessionEntry in dayValue.entries) {
        sessions.add(
          TimetableSession(
            day: day,
            timeRange: sessionEntry.key.toString(),
            classroomTitle: sessionEntry.value?.toString() ?? '',
          ),
        );
      }
    }

    sessions.sort((left, right) {
      final dayCompare = left.day.compareTo(right.day);
      if (dayCompare != 0) {
        return dayCompare;
      }
      return left.timeRange.compareTo(right.timeRange);
    });
    return sessions;
  }
}
