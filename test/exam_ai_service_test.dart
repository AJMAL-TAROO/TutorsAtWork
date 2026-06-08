import 'package:flutter_test/flutter_test.dart';
import 'package:taw_app/models/app_user.dart';
import 'package:taw_app/services/exam_ai_service.dart';
import 'package:taw_app/services/firebase_database_service.dart';

void main() {
  const tutor = AppUser(
    key: 'ADMIN_001',
    email: 'tutor@example.com',
    fullName: 'Tutor',
    role: UserRole.admin,
  );
  final now = DateTime.utc(2026, 6, 8, 12);

  test('creates a session and atomically removes expired sessions', () async {
    final database = _FakeDatabaseService({
      'active': {
        'EXPIRES_AT_MS': now
            .add(const Duration(minutes: 5))
            .millisecondsSinceEpoch,
      },
      'expired_numeric': {
        'EXPIRES_AT_MS': now
            .subtract(const Duration(minutes: 1))
            .millisecondsSinceEpoch,
      },
      'expired_text': {
        'EXPIRES_AT': now.subtract(const Duration(hours: 1)).toIso8601String(),
      },
      'invalid': {'ADMIN_KEY': 'ADMIN_OLD'},
    });
    final service = ExamAiService(databaseService: database, now: () => now);

    final uri = await service.createSessionUri(tutor);

    expect(database.updatedPath, 'EXAM_AI/SESSIONS');
    expect(database.updatedValues['expired_numeric'], isNull);
    expect(database.updatedValues['expired_text'], isNull);
    expect(database.updatedValues['invalid'], isNull);
    expect(database.updatedValues.containsKey('active'), isFalse);
    expect(database.setPath, isNull);

    final token = uri.queryParameters['session'];
    expect(token, isNotNull);
    expect(database.updatedValues[token], {
      'ADMIN_KEY': tutor.key,
      'EXPIRES_AT': now.add(ExamAiService.sessionDuration).toIso8601String(),
      'EXPIRES_AT_MS': now
          .add(ExamAiService.sessionDuration)
          .millisecondsSinceEpoch,
    });
  });

  test('still creates the new session when cleanup fails', () async {
    final database = _FakeDatabaseService(null, failGet: true);
    final service = ExamAiService(databaseService: database, now: () => now);

    final uri = await service.createSessionUri(tutor);
    final token = uri.queryParameters['session'];

    expect(database.setPath, 'EXAM_AI/SESSIONS/$token');
    expect(database.setValue, isA<Map<String, Object>>());
  });
}

class _FakeDatabaseService extends FirebaseDatabaseService {
  _FakeDatabaseService(this.sessions, {this.failGet = false});

  final Object? sessions;
  final bool failGet;

  String? updatedPath;
  Map<String, Object?> updatedValues = {};
  String? setPath;
  Object? setValue;

  @override
  Future<Object?> get(String path) async {
    if (failGet) {
      throw StateError('read failed');
    }
    return sessions;
  }

  @override
  Future<void> update(String path, Map<String, Object?> value) async {
    updatedPath = path;
    updatedValues = value;
  }

  @override
  Future<void> set(String path, Object? value) async {
    setPath = path;
    setValue = value;
  }
}
