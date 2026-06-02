import 'package:intl/intl.dart';

import '../models/app_user.dart';
import '../models/student.dart';
import '../models/student_feedback.dart';
import 'firebase_database_service.dart';

abstract class StudentFeedbackService {
  Stream<List<StudentFeedback>> watchFeedbackForUser(AppUser user);

  Future<void> createFeedback({
    required AppUser tutor,
    required Student student,
    required String message,
  });

  Future<void> updateFeedback({
    required AppUser tutor,
    required StudentFeedback feedback,
    required String message,
  });

  Future<void> deleteFeedback({
    required AppUser tutor,
    required StudentFeedback feedback,
  });
}

class RealtimeDatabaseStudentFeedbackService implements StudentFeedbackService {
  RealtimeDatabaseStudentFeedbackService({
    FirebaseDatabaseService? databaseService,
  }) : _databaseService = databaseService ?? FirebaseDatabaseService();

  final FirebaseDatabaseService _databaseService;

  @override
  Stream<List<StudentFeedback>> watchFeedbackForUser(AppUser user) {
    return _databaseService.watch(_feedbackPath).map((value) {
      return _feedbackFromValue(
        value,
      ).where((feedback) => _canUserViewFeedback(user, feedback)).toList();
    });
  }

  @override
  Future<void> createFeedback({
    required AppUser tutor,
    required Student student,
    required String message,
  }) async {
    if (tutor.role != UserRole.admin) {
      throw StateError('Only tutors can send feedback.');
    }

    final now = DateTime.now();
    final id = 'FEEDBACK_${now.millisecondsSinceEpoch}';
    await _databaseService.update(_feedbackPath, {
      id: {
        'STUDENT_KEY': student.key,
        'STUDENT_NAME': student.fullName,
        'TUTOR_KEY': tutor.key,
        'TUTOR_NAME': tutor.fullName,
        'TUTOR_EMAIL': tutor.email,
        'DATE': _dateFormat.format(now),
        'UPDATED_DATE': '',
        'TIMESTAMP': now.millisecondsSinceEpoch,
        'MESSAGE': message,
      },
    });
  }

  @override
  Future<void> updateFeedback({
    required AppUser tutor,
    required StudentFeedback feedback,
    required String message,
  }) async {
    _ensureOwnFeedback(tutor, feedback);
    await _databaseService.update('$_feedbackPath/${feedback.id}', {
      'MESSAGE': message,
      'UPDATED_DATE': _dateFormat.format(DateTime.now()),
    });
  }

  @override
  Future<void> deleteFeedback({
    required AppUser tutor,
    required StudentFeedback feedback,
  }) async {
    _ensureOwnFeedback(tutor, feedback);
    await _databaseService.remove('$_feedbackPath/${feedback.id}');
  }

  List<StudentFeedback> _feedbackFromValue(Object? value) {
    if (value is! Map) {
      return const [];
    }

    final feedback = <StudentFeedback>[];
    for (final entry in value.entries) {
      final data = entry.value;
      if (data is Map) {
        feedback.add(
          StudentFeedback.fromRealtimeDatabase(
            id: entry.key.toString(),
            data: data,
          ),
        );
      }
    }
    feedback.sort((left, right) {
      final byTimestamp = right.timestamp.compareTo(left.timestamp);
      return byTimestamp == 0 ? right.id.compareTo(left.id) : byTimestamp;
    });
    return feedback;
  }

  bool _canUserViewFeedback(AppUser user, StudentFeedback feedback) {
    return user.role == UserRole.admin
        ? feedback.tutorKey == user.key
        : feedback.studentKey == user.key;
  }

  void _ensureOwnFeedback(AppUser tutor, StudentFeedback feedback) {
    if (tutor.role != UserRole.admin || feedback.tutorKey != tutor.key) {
      throw StateError('Only the tutor who sent this feedback can change it.');
    }
  }

  String get _feedbackPath => 'FEEDBACK';

  DateFormat get _dateFormat => DateFormat('yyyy-MM-dd HH:mm');
}
