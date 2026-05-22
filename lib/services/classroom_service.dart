import 'firebase_database_service.dart';
import '../models/classroom.dart';

abstract class ClassroomService {
  Future<List<Classroom>> classroomsForRoomIds(List<int> roomIds);
}

class RealtimeDatabaseClassroomService implements ClassroomService {
  RealtimeDatabaseClassroomService({FirebaseDatabaseService? databaseService})
    : _databaseService = databaseService ?? FirebaseDatabaseService();

  final FirebaseDatabaseService _databaseService;

  @override
  Future<List<Classroom>> classroomsForRoomIds(List<int> roomIds) async {
    if (roomIds.isEmpty) {
      return const [];
    }

    final classrooms = await _databaseService.get(_databaseService.classrooms);

    if (classrooms is! Map) {
      return const [];
    }

    final allowedRoomIds = roomIds.toSet();
    final results = <Classroom>[];

    for (final value in classrooms.values) {
      if (value is! Map) {
        continue;
      }

      final classroom = Classroom.fromRealtimeDatabase(value);
      if (allowedRoomIds.contains(classroom.id)) {
        results.add(classroom);
      }
    }

    results.sort((left, right) => left.id.compareTo(right.id));
    return results;
  }
}
