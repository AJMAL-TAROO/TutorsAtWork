import '../models/student.dart';
import 'firebase_database_service.dart';

abstract class StudentService {
  Stream<List<Student>> watchStudentsForAdmin(String adminKey);

  Future<List<Student>> studentsForAdmin(String adminKey);

  Future<List<Student>> studentsForClassroom(int classroomId);

  Future<Student> createStudent({
    required String adminKey,
    required StudentDraft draft,
  });

  Future<void> updateStudent({
    required Student student,
    required StudentDraft draft,
  });

  Future<void> deleteStudent({
    required String adminKey,
    required Student student,
  });

  Future<void> assignStudentToClassroom({
    required Student student,
    required int classroomId,
  });

  Future<void> removeStudentFromClassroom({
    required Student student,
    required int classroomId,
  });
}

class RealtimeDatabaseStudentService implements StudentService {
  RealtimeDatabaseStudentService({FirebaseDatabaseService? databaseService})
    : _databaseService = databaseService ?? FirebaseDatabaseService();

  final FirebaseDatabaseService _databaseService;

  @override
  Stream<List<Student>> watchStudentsForAdmin(String adminKey) {
    return _databaseService.watch(_databaseService.students).asyncMap((_) {
      return studentsForAdmin(adminKey);
    });
  }

  @override
  Future<List<Student>> studentsForAdmin(String adminKey) async {
    final adminValue = await _databaseService.get('ADMIN/$adminKey');
    if (adminValue is! Map) {
      return const [];
    }
    final studentKeys = _stringIds(adminValue['STUDENTS']).toSet();
    if (studentKeys.isEmpty) {
      return const [];
    }

    final value = await _databaseService.get(_databaseService.students);
    final students =
        _studentsFromValue(
            value,
          ).where((student) => studentKeys.contains(student.key)).toList()
          ..sort((left, right) => left.fullName.compareTo(right.fullName));
    return students;
  }

  @override
  Future<List<Student>> studentsForClassroom(int classroomId) async {
    final value = await _databaseService.get(_databaseService.students);
    return _studentsFromValue(value)
        .where((student) => student.virtualRoomIds.contains(classroomId))
        .toList()
      ..sort((left, right) => left.fullName.compareTo(right.fullName));
  }

  @override
  Future<Student> createStudent({
    required String adminKey,
    required StudentDraft draft,
  }) async {
    final counterPath = 'NUMBERS/ID_STUDENT/NUMBER';
    final counter = await _databaseService.get(counterPath);
    final nextId = int.tryParse(counter?.toString() ?? '') ?? 1;
    final studentKey = 'STUDENTS_$nextId';

    await _databaseService.set(
      '${_databaseService.students}/$studentKey',
      draft.toRealtimeDatabase(virtualRoomIds: const []),
    );
    await _addStudentToAdmin(adminKey: adminKey, studentKey: studentKey);
    await _databaseService.set(counterPath, nextId + 1);
    await _databaseService.set('ADMIN/$adminKey/LOGS/LAST_CREATED_STUDENT', {
      'STUDENT_ID': studentKey,
      'STUDENT_NAME': draft.fullName,
      'TIMESTAMP': DateTime.now().millisecondsSinceEpoch,
      'DATE': DateTime.now().toIso8601String(),
    });

    return Student(
      key: studentKey,
      fullName: draft.fullName,
      telephone: draft.telephone,
      responsibleParty: draft.responsibleParty,
      responsiblePartyTelephone: draft.responsiblePartyTelephone,
      email: draft.email,
      password: draft.password,
      virtualRoomIds: const [],
    );
  }

  @override
  Future<void> updateStudent({
    required Student student,
    required StudentDraft draft,
  }) async {
    await _databaseService
        .update('${_databaseService.students}/${student.key}', {
          'FULL_NAME': draft.fullName,
          'TEL': draft.telephone,
          'R_PARTY': draft.responsibleParty,
          'R_PARTY_TEL': draft.responsiblePartyTelephone,
          'EMAIL': draft.email,
          'PASSWORD': draft.password,
        });
  }

  @override
  Future<void> deleteStudent({
    required String adminKey,
    required Student student,
  }) async {
    await _removeStudentFromAdmin(adminKey: adminKey, studentKey: student.key);
    await _databaseService.remove(
      '${_databaseService.students}/${student.key}',
    );
  }

  @override
  Future<void> assignStudentToClassroom({
    required Student student,
    required int classroomId,
  }) async {
    final rooms = {...student.virtualRoomIds, classroomId}.toList()..sort();
    await _databaseService.update(
      '${_databaseService.students}/${student.key}',
      {'VIRTUAL_ROOMS': rooms.join(',')},
    );
  }

  @override
  Future<void> removeStudentFromClassroom({
    required Student student,
    required int classroomId,
  }) async {
    final rooms =
        student.virtualRoomIds
            .where((roomId) => roomId != classroomId)
            .toSet()
            .toList()
          ..sort();
    await _databaseService.update(
      '${_databaseService.students}/${student.key}',
      {'VIRTUAL_ROOMS': rooms.join(',')},
    );
  }

  List<Student> _studentsFromValue(Object? value) {
    final students = <Student>[];
    if (value is! Map) {
      return students;
    }
    for (final entry in value.entries) {
      final data = entry.value;
      if (data is Map) {
        students.add(
          Student.fromRealtimeDatabase(key: entry.key.toString(), data: data),
        );
      }
    }
    return students;
  }

  Future<void> _addStudentToAdmin({
    required String adminKey,
    required String studentKey,
  }) async {
    final current = await _databaseService.get('ADMIN/$adminKey/STUDENTS');
    final ids = _stringIds(current)..add(studentKey);
    await _databaseService.set(
      'ADMIN/$adminKey/STUDENTS',
      ids.toSet().join(','),
    );
  }

  Future<void> _removeStudentFromAdmin({
    required String adminKey,
    required String studentKey,
  }) async {
    final current = await _databaseService.get('ADMIN/$adminKey/STUDENTS');
    final ids = _stringIds(current).where((id) => id != studentKey);
    await _databaseService.set('ADMIN/$adminKey/STUDENTS', ids.join(','));
  }

  List<String> _stringIds(Object? value) {
    return (value?.toString() ?? '')
        .split(',')
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toList();
  }
}
