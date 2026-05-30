import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/student.dart';
import 'attendance_provider.dart';
import 'auth_provider.dart';

final studentsProvider = StreamProvider<List<Student>>((ref) {
  final user = ref.watch(currentUserProvider);
  final service = ref.watch(studentServiceProvider);
  if (user == null) {
    return Stream.value(const <Student>[]);
  }
  return service.watchStudentsForAdmin(user.key);
});
