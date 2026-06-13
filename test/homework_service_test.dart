import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:taw_app/models/app_user.dart';
import 'package:taw_app/models/homework_file.dart';
import 'package:taw_app/services/firebase_database_service.dart';
import 'package:taw_app/services/homework_service.dart';
import 'package:taw_app/services/storage_service.dart';
import 'package:taw_app/utils/note_file_picker.dart';

void main() {
  const student = AppUser(
    key: 'STUDENTS_14',
    email: 'student@example.com',
    fullName: 'Jane Student',
    role: UserRole.student,
    virtualRoomIds: [1083],
  );
  const otherStudent = AppUser(
    key: 'STUDENTS_21',
    email: 'other@example.com',
    fullName: 'Other Student',
    role: UserRole.student,
    virtualRoomIds: [1083],
  );
  const tutor = AppUser(
    key: 'ADMIN_8',
    email: 'tutor@example.com',
    fullName: 'Tutor',
    role: UserRole.admin,
    virtualRoomIds: [1083],
  );

  test(
    'student upload writes ownership metadata and reserves a numeric ID',
    () async {
      final database = _FakeDatabaseService();
      final storage = _FakeStorageService();
      final service = FirebaseHomeworkService(
        databaseService: database,
        storageService: storage,
      );

      final homework = await service.uploadHomework(
        classroomId: 1083,
        file: const PickedNoteFile(
          name: 'database-homework.pdf',
          size: 3,
          bytes: [1, 2, 3],
        ),
        uploadedBy: student,
      );

      expect(homework.id, 2);
      expect(storage.uploadedPath, '1083_HOMEWORK/2');
      expect(database.values['1083_HOMEWORK/2'], {
        'ID': 2,
        'Name': 'database-homework.pdf',
        'Link': 'https://example.test/1083_HOMEWORK/2',
        'Time': homework.createdAt.millisecondsSinceEpoch,
        'STUDENT_KEY': 'STUDENTS_14',
        'STUDENT_NAME': 'Jane Student',
      });
    },
  );

  test('tutor can view all homework but cannot upload or manage it', () async {
    final database = _FakeDatabaseService()
      ..values['1083_HOMEWORK'] = {
        '2': _record(2, student),
        '3': _record(3, otherStudent),
      };
    final service = FirebaseHomeworkService(
      databaseService: database,
      storageService: _FakeStorageService(),
    );

    final items = await service
        .watchHomework(classroomId: 1083, user: tutor)
        .first;
    expect(items.map((item) => item.id), [3, 2]);
    expect(
      () => service.uploadHomework(
        classroomId: 1083,
        file: const PickedNoteFile(name: 'work.pdf', size: 1, bytes: [1]),
        uploadedBy: tutor,
      ),
      throwsStateError,
    );
  });

  test('student sees and can manage only their own homework', () async {
    final database = _FakeDatabaseService()
      ..values['1083_HOMEWORK'] = {
        '2': _record(2, student),
        '3': _record(3, otherStudent),
      }
      ..values['1083_HOMEWORK/2'] = _record(2, student)
      ..values['1083_HOMEWORK/3'] = _record(3, otherStudent);
    final storage = _FakeStorageService();
    final service = FirebaseHomeworkService(
      databaseService: database,
      storageService: storage,
    );

    final visible = await service
        .watchHomework(classroomId: 1083, user: student)
        .first;
    expect(visible.map((item) => item.id), [2]);

    await service.renameHomework(
      classroomId: 1083,
      homework: HomeworkFile.fromRealtimeDatabase(_record(2, student)),
      newName: 'renamed.pdf',
      user: student,
    );
    expect(database.updates['1083_HOMEWORK/2'], {'Name': 'renamed.pdf'});

    expect(
      () => service.deleteHomework(
        classroomId: 1083,
        homework: HomeworkFile.fromRealtimeDatabase(_record(3, otherStudent)),
        user: student,
      ),
      throwsStateError,
    );
  });

  test('rejects unsupported homework file types', () async {
    final service = FirebaseHomeworkService(
      databaseService: _FakeDatabaseService(),
      storageService: _FakeStorageService(),
    );

    expect(
      () => service.uploadHomework(
        classroomId: 1083,
        file: const PickedNoteFile(name: 'archive.zip', size: 1, bytes: [1]),
        uploadedBy: student,
      ),
      throwsStateError,
    );
  });
}

Map<String, Object> _record(int id, AppUser student) {
  return {
    'ID': id,
    'Name': 'homework-$id.pdf',
    'Link': 'https://example.test/1083_HOMEWORK/$id',
    'Time': 1781366400000,
    'STUDENT_KEY': student.key,
    'STUDENT_NAME': student.fullName,
  };
}

class _FakeDatabaseService extends FirebaseDatabaseService {
  final values = <String, Object?>{};
  final updates = <String, Map<String, Object?>>{};
  int counter = 1;

  @override
  Future<Object?> get(String path) async => values[path];

  @override
  Future<void> set(String path, Object? value) async {
    values[path] = value;
  }

  @override
  Future<void> update(String path, Map<String, Object?> value) async {
    updates[path] = value;
  }

  @override
  Future<void> remove(String path) async {
    values.remove(path);
  }

  @override
  Stream<Object?> watch(String path) => Stream.value(values[path]);

  @override
  Future<int> reserveNextCounter(
    String path, {
    int minimumCurrentValue = 1,
    int maxAttempts = 8,
  }) async {
    counter = counter < minimumCurrentValue ? minimumCurrentValue : counter;
    return ++counter;
  }
}

class _FakeStorageService extends StorageService {
  String? uploadedPath;

  @override
  Future<String> uploadHomeworkFile({
    required int classroomId,
    required int homeworkId,
    required List<int> bytes,
    required String fileName,
    required String? contentType,
  }) async {
    uploadedPath = '${classroomId}_HOMEWORK/$homeworkId';
    return 'https://example.test/$uploadedPath';
  }

  @override
  Future<void> deleteHomeworkFile(int classroomId, int homeworkId) async {}
}
