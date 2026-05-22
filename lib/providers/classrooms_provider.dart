import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/classroom.dart';
import '../services/classroom_service.dart';
import 'auth_provider.dart';

final classroomServiceProvider = Provider<ClassroomService>((ref) {
  return RealtimeDatabaseClassroomService();
});

final classroomsProvider = FutureProvider<List<Classroom>>((ref) async {
  final user = ref.watch(currentUserProvider);
  final service = ref.watch(classroomServiceProvider);

  return service.classroomsForRoomIds(user?.virtualRoomIds ?? const []);
});
