import 'package:intl/intl.dart';

import '../models/classroom_comment.dart';
import 'firebase_database_service.dart';

abstract class ClassroomCommentService {
  Stream<List<ClassroomComment>> watchComments(int classroomId);

  Future<void> addComment({
    required int classroomId,
    required String email,
    required String authorKey,
    required String authorRole,
    required String comment,
  });

  Future<void> updateComment({
    required int classroomId,
    required String commentId,
    required String comment,
  });

  Future<void> deleteComment({
    required int classroomId,
    required String commentId,
  });
}

class RealtimeDatabaseClassroomCommentService
    implements ClassroomCommentService {
  RealtimeDatabaseClassroomCommentService({
    FirebaseDatabaseService? databaseService,
  }) : _databaseService = databaseService ?? FirebaseDatabaseService();

  final FirebaseDatabaseService _databaseService;

  @override
  Stream<List<ClassroomComment>> watchComments(int classroomId) {
    return _databaseService
        .watch(_commentsPath(classroomId))
        .map(_commentsFromValue);
  }

  @override
  Future<void> addComment({
    required int classroomId,
    required String email,
    required String authorKey,
    required String authorRole,
    required String comment,
  }) async {
    final id = 'COMMENT_${DateTime.now().millisecondsSinceEpoch}';
    await _databaseService.update(_commentsPath(classroomId), {
      id: {
        'EMAIL': email,
        'AUTHOR_KEY': authorKey,
        'AUTHOR_ROLE': authorRole,
        'DATE': DateFormat('yyyy-MM-dd').format(DateTime.now()),
        'COMMENT': comment,
      },
    });
  }

  @override
  Future<void> updateComment({
    required int classroomId,
    required String commentId,
    required String comment,
  }) async {
    await _databaseService.update('${_commentsPath(classroomId)}/$commentId', {
      'COMMENT': comment,
    });
  }

  @override
  Future<void> deleteComment({
    required int classroomId,
    required String commentId,
  }) {
    return _databaseService.remove('${_commentsPath(classroomId)}/$commentId');
  }

  List<ClassroomComment> _commentsFromValue(Object? value) {
    if (value is! Map) {
      return const [];
    }
    final comments = <ClassroomComment>[];
    for (final entry in value.entries) {
      final data = entry.value;
      if (data is Map) {
        comments.add(
          ClassroomComment.fromRealtimeDatabase(
            id: entry.key.toString(),
            data: data,
          ),
        );
      }
    }
    comments.sort((left, right) => right.id.compareTo(left.id));
    return comments;
  }

  String _commentsPath(int classroomId) {
    return '${_databaseService.classrooms}/CLASSROOM_$classroomId/COMMENTS';
  }
}
