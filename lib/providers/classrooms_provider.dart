import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/classroom.dart';
import '../services/classroom_service.dart';
import 'auth_provider.dart';

final classroomServiceProvider = Provider<ClassroomService>((ref) {
  return RealtimeDatabaseClassroomService();
});

final classroomsProvider = StreamProvider<List<Classroom>>((ref) {
  final user = ref.watch(currentUserProvider);
  final service = ref.watch(classroomServiceProvider);
  if (user == null) {
    return Stream.value(const <Classroom>[]);
  }

  return service.watchClassroomsForUser(user);
});
