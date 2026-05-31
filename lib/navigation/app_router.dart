import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/classroom.dart';
import '../providers/auth_provider.dart';
import '../screens/attendance/attendance_screen.dart';
import '../screens/classroom_comments/classroom_comments_screen.dart';
import '../screens/classrooms/classrooms_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/login/login_screen.dart';
import '../screens/notes/notes_screen.dart';
import '../screens/students/students_screen.dart';
import '../screens/timetable/timetable_screen.dart';
import 'app_routes.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final user = ref.watch(currentUserProvider);

  return GoRouter(
    initialLocation: user == null ? AppRoutes.login : AppRoutes.dashboard,
    redirect: (context, state) {
      final isLoggingIn = state.uri.path == AppRoutes.login;
      if (user == null && !isLoggingIn) {
        return AppRoutes.login;
      }
      if (user != null && isLoggingIn) {
        return AppRoutes.dashboard;
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
