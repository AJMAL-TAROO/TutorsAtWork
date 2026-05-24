import '../models/student.dart';
import 'firebase_database_service.dart';

abstract class StudentService {
  Future<List<Student>> studentsForClassroom(int classroomId);
}

class RealtimeDatabaseStudentService implements StudentService {
  RealtimeDatabaseStudentService({FirebaseDatabaseService? databaseService})
    : _databaseService = databaseService ?? FirebaseDatabaseService();

  final FirebaseDatabaseService _databaseService;

  @override
  Future<List<Student>> studentsForClassroom(int classroomId) async {
    final value = await _databaseService.get(_databaseService.students);
    if (value is! Map) {
      return const [];
    }

    final students = <Student>[];
    for (final entry in value.entries) {
      final data = entry.value;
      if (data is! Map) {
        continue;
      }

      final student = Student.fromRealtimeDatabase(
        key: entry.key.toString(),
        data: data,
      );
      if (student.virtualRoomIds.contains(classroomId)) {
        students.add(student);
      }
    }

    students.sort((left, right) => left.fullName.compareTo(right.fullName));
    return students;
  }
}
