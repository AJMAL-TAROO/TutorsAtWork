import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_user.dart';
import '../models/homework_file.dart';
import '../services/homework_service.dart';

final homeworkServiceProvider = Provider<HomeworkService>((ref) {
  return FirebaseHomeworkService();
});

typedef HomeworkQuery = ({int classroomId, AppUser user});

final homeworkProvider =
    StreamProvider.family<List<HomeworkFile>, HomeworkQuery>((ref, query) {
      return ref
          .watch(homeworkServiceProvider)
          .watchHomework(classroomId: query.classroomId, user: query.user);
    });
