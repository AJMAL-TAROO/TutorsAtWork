import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/classroom.dart';
import '../screens/attendance/attendance_screen.dart';
import '../screens/classrooms/classrooms_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/login/login_screen.dart';
import '../screens/notes/notes_screen.dart';
import '../screens/timetable/timetable_screen.dart';
import 'app_routes.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.login,
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
    ],
  );
});
