import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/student_feedback.dart';
import '../services/student_feedback_service.dart';
import 'auth_provider.dart';

final studentFeedbackServiceProvider = Provider<StudentFeedbackService>((ref) {
  return RealtimeDatabaseStudentFeedbackService();
});

final studentFeedbackProvider = StreamProvider<List<StudentFeedback>>((ref) {
  final user = ref.watch(currentUserProvider);
  final service = ref.watch(studentFeedbackServiceProvider);
  if (user == null) {
    return Stream.value(const <StudentFeedback>[]);
  }

  return service.watchFeedbackForUser(user);
});
