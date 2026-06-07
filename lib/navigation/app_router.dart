import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/app_user.dart';
import '../models/classroom.dart';
import '../providers/auth_provider.dart';
import '../screens/attendance/attendance_screen.dart';
import '../screens/classroom_comments/classroom_comments_screen.dart';
import '../screens/classrooms/classrooms_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/exam_ai/exam_ai_screen.dart';
import '../screens/feedback/feedback_screen.dart';
import '../screens/login/login_screen.dart';
import '../screens/notes/notes_screen.dart';
import '../screens/students/students_screen.dart';
import '../screens/timetable/timetable_screen.dart';
import '../screens/whiteboard/whiteboard_screen.dart';
import 'app_routes.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final user = ref.watch(currentUserProvider);

  return GoRouter(
    initialLocation: user == null ? AppRoutes.login : AppRoutes.dashboard,
    redirect: (context, state) {
      final path = state.uri.path;
      final isLoggingIn = path == AppRoutes.login;
      if (user == null && !isLoggingIn) {
        return AppRoutes.login;
      }
      if (user != null && isLoggingIn) {
        return AppRoutes.dashboard;
      }
      if (user?.role == UserRole.student &&
          _studentBlockedPaths.contains(path)) {
        return AppRoutes.dashboard;
      }
      final classroomChildRouteId = _classroomChildRouteId(path);
      if (user != null &&
          classroomChildRouteId != null &&
          !user.virtualRoomIds.contains(classroomChildRouteId)) {
        return AppRoutes.classrooms;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.dashboard,
        name: 'dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: AppRoutes.classrooms,
        name: 'classrooms',
        builder: (context, state) => const ClassroomsScreen(),
      ),
      GoRoute(
        path: AppRoutes.students,
        name: 'students',
        builder: (context, state) => const StudentsScreen(),
      ),
      GoRoute(
        path: AppRoutes.timetable,
        name: 'timetable',
        builder: (context, state) => const TimetableScreen(),
      ),
      GoRoute(
        path: AppRoutes.attendance,
        name: 'attendance',
        builder: (context, state) => const AttendanceScreen(),
      ),
      GoRoute(
        path: AppRoutes.feedback,
        name: 'feedback',
        builder: (context, state) => const FeedbackScreen(),
      ),
      GoRoute(
        path: AppRoutes.whiteboard,
        name: 'whiteboard',
        builder: (context, state) => const WhiteboardScreen(),
      ),
      GoRoute(
        path: AppRoutes.examAi,
        name: 'exam-ai',
        builder: (context, state) => ExamAiScreen(
          initialUrl: state.extra is String ? state.extra as String : null,
        ),
      ),
      GoRoute(
        path: AppRoutes.classroomNotes,
        name: 'classroom-notes',
        builder: (context, state) {
          final classroomId =
              int.tryParse(state.pathParameters['classroomId'] ?? '') ?? 0;
          final classroom = state.extra is Classroom
              ? state.extra as Classroom
              : null;

          return NotesScreen(
            classroomId: classroomId,
            classroomTitle: classroom?.title ?? 'Classroom $classroomId',
            storageFolder: classroom?.storageFolder ?? '${classroomId}_NOTES',
          );
        },
      ),
      GoRoute(
        path: AppRoutes.classroomComments,
        name: 'classroom-comments',
        builder: (context, state) {
          final classroomId =
              int.tryParse(state.pathParameters['classroomId'] ?? '') ?? 0;
          final classroom = state.extra is Classroom
              ? state.extra as Classroom
              : null;

          return ClassroomCommentsScreen(
            classroomId: classroomId,
            classroomTitle: classroom?.title ?? 'Classroom $classroomId',
          );
        },
      ),
    ],
  );
});

const _studentBlockedPaths = {
  AppRoutes.students,
  AppRoutes.timetable,
  AppRoutes.attendance,
  AppRoutes.whiteboard,
  AppRoutes.examAi,
};

int? _classroomChildRouteId(String path) {
  final match = RegExp(
    r'^/classrooms/(\d+)/(notes|comments)$',
  ).firstMatch(path);
  if (match == null) {
    return null;
  }
  return int.tryParse(match.group(1) ?? '');
}
