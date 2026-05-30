import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/classroom_comment.dart';
import '../services/classroom_comment_service.dart';

final classroomCommentServiceProvider = Provider<ClassroomCommentService>((
  ref,
) {
  return RealtimeDatabaseClassroomCommentService();
});

final classroomCommentsProvider =
    StreamProvider.family<List<ClassroomComment>, int>((ref, classroomId) {
      final service = ref.watch(classroomCommentServiceProvider);
      return service.watchComments(classroomId);
    });
