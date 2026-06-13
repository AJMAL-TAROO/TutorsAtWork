import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/app_user.dart';
import '../../models/classroom.dart';
import '../../models/timetable_session.dart';
import '../../navigation/app_routes.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/classrooms_provider.dart';
import '../../providers/student_feedback_provider.dart';
import '../../providers/students_provider.dart';
import '../../providers/timetable_provider.dart';
import '../../widgets/app_shell.dart';
import '../../widgets/required_update_gate.dart';

final _dashboardClockProvider = StreamProvider<DateTime>((ref) async* {
  yield DateTime.now();
  yield* Stream.periodic(const Duration(minutes: 1), (_) => DateTime.now());
});

final _attendanceDashboardSummaryProvider = FutureProvider<String>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    return 'Attendance unavailable';
  }

  final now = ref
      .watch(_dashboardClockProvider)
      .maybeWhen(data: (value) => value, orElse: DateTime.now);
  final sessions = await ref.watch(timetableProvider.future);
  final classrooms = await ref.watch(classroomsProvider.future);
  final dueClassroomIds = _dueClassroomIdsForToday(
    sessions: sessions,
    classrooms: classrooms,
    now: now,
  );

  if (dueClassroomIds.isEmpty) {
    final hasTodaySessions = sessions.any(
      (session) => session.day == now.weekday,
    );
    return hasTodaySessions ? 'Attendance not due' : 'No class today';
  }

  final service = ref.read(attendanceServiceProvider);
  var takenCount = 0;
  for (final classroomId in dueClassroomIds) {
    final records = await service.attendanceForDate(
      date: now,
      adminKey: user.key,
      classroomId: classroomId,
    );
    if (records.isNotEmpty) {
      takenCount += 1;
    }
  }

  if (takenCount == 0) {
    return 'Attendance not taken';
  }
  if (takenCount < dueClassroomIds.length) {
    return 'Some attendance missing';
  }
  return 'Attendance taken';
});

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final isAdmin = user?.role == UserRole.admin;
    final classrooms = ref.watch(classroomsProvider);
    final feedback = ref.watch(studentFeedbackProvider);
    final students = isAdmin ? ref.watch(studentsProvider) : null;
    final timetable = isAdmin ? ref.watch(timetableProvider) : null;
    final attendanceSummary = isAdmin
        ? ref.watch(_attendanceDashboardSummaryProvider)
        : null;
    final now = ref
        .watch(_dashboardClockProvider)
        .maybeWhen(data: (value) => value, orElse: DateTime.now);
    final timetableSummary =
        timetable?.maybeWhen(
          data: (sessions) => _todayTimetableSummary(sessions, now),
          loading: () => 'Checking timetable...',
          error: (error, stackTrace) => 'Timetable unavailable',
          orElse: () => 'No session today',
        ) ??
        '-';
    final attendanceValue =
        attendanceSummary?.maybeWhen(
          data: (summary) => summary,
          loading: () => 'Checking attendance...',
          error: (error, stackTrace) => 'Attendance unavailable',
          orElse: () => 'Attendance unavailable',
        ) ??
        '-';

    return RequiredUpdateGate(
      child: AppShell(
        title: 'Dashboard',
        onBack: () => _confirmExit(context),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            onPressed: () async {
              await ref.read(currentUserProvider.notifier).clear();
              if (!context.mounted) {
                return;
              }
              context.go(AppRoutes.login);
            },
            icon: const Icon(Icons.logout),
          ),
        ],
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              'Welcome${user == null ? '' : ', ${user.fullName}'}',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              isAdmin
                  ? 'Your classroom access, notes, timetable, attendance, and student feedback live here.'
                  : 'Your classrooms, notes, comments, and tutor feedback live here.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            LayoutBuilder(
              builder: (context, constraints) {
                final tileWidth = constraints.maxWidth < 520
                    ? constraints.maxWidth
                    : 220.0;
                return Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    _DashboardTile(
                      width: tileWidth,
                      icon: Icons.school_outlined,
                      title: 'Classrooms',
                      value: classrooms.maybeWhen(
                        data: (items) => items.length.toString(),
                        orElse: () => '-',
                      ),
                      onTap: () => context.go(AppRoutes.classrooms),
                    ),
                    _DashboardTile(
                      width: tileWidth,
                      icon: Icons.rate_review_outlined,
                      title: 'Feedback',
                      value: feedback.maybeWhen(
                        data: (items) => items.length.toString(),
                        loading: () => 'Loading...',
                        orElse: () => '-',
                      ),
                      onTap: () => context.go(AppRoutes.feedback),
                    ),
                    if (isAdmin) ...[
                      _DashboardTile(
                        width: tileWidth,
                        icon: Icons.people_outline,
                        title: 'Students',
                        value:
                            students?.maybeWhen(
                              data: (items) => items.length.toString(),
                              orElse: () => '-',
                            ) ??
                            '-',
                        onTap: () => context.go(AppRoutes.students),
                      ),
                      _DashboardTile(
                        width: tileWidth,
                        icon: Icons.calendar_month_outlined,
                        title: 'Timetable',
                        value: timetableSummary,
                        onTap: () => context.go(AppRoutes.timetable),
                      ),
                      _DashboardTile(
                        width: tileWidth,
                        icon: Icons.fact_check_outlined,
                        title: 'Attendance',
                        value: attendanceValue,
                        onTap: () => context.go(AppRoutes.attendance),
                      ),
                      _DashboardTile(
                        width: tileWidth,
                        icon: Icons.draw_outlined,
                        title: 'Whiteboard',
                        value: 'Open',
                        onTap: () => context.go(AppRoutes.whiteboard),
                      ),
                      _DashboardTile(
                        width: tileWidth,
                        icon: Icons.description_outlined,
                        title: 'Exam AI',
                        value: 'Open',
                        onTap: () => context.go(AppRoutes.examAi),
                      ),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String _todayTimetableSummary(List<TimetableSession> sessions, DateTime now) {
    final todaySessions =
        sessions
            .where((session) => session.day == now.weekday)
            .map((session) => _TimedSession.fromSession(session))
            .whereType<_TimedSession>()
            .toList()
          ..sort(
            (left, right) => left.startMinutes.compareTo(right.startMinutes),
          );

    if (todaySessions.isEmpty) {
      return 'No session today';
    }

    final currentMinutes = (now.hour * 60) + now.minute;
    for (final session in todaySessions) {
      if (currentMinutes >= session.startMinutes &&
          currentMinutes < session.endMinutes) {
        return '${session.classroomTitle} in progress';
      }
      if (currentMinutes < session.startMinutes) {
        return '${session.classroomTitle} ${session.timeRange}';
      }
    }

    return 'No more sessions today';
  }

  Future<void> _confirmExit(BuildContext context) async {
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave app?'),
        content: const Text('Your session will stay signed in.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Leave'),
          ),
        ],
      ),
    );

    if (shouldExit == true) {
      await SystemNavigator.pop();
    }
  }
}

Set<int> _dueClassroomIdsForToday({
  required List<TimetableSession> sessions,
  required List<Classroom> classrooms,
  required DateTime now,
}) {
  final currentMinutes = (now.hour * 60) + now.minute;
  final classroomsByTitle = {
    for (final classroom in classrooms)
      _normalizeTitle(classroom.title): classroom,
  };
  final dueIds = <int>{};

  for (final session in sessions) {
    if (session.day != now.weekday) {
      continue;
    }
    final timedSession = _TimedSession.fromSession(session);
    if (timedSession == null || currentMinutes < timedSession.endMinutes) {
      continue;
    }
    final classroom =
        classroomsByTitle[_normalizeTitle(session.classroomTitle)];
    if (classroom != null) {
      dueIds.add(classroom.id);
    }
  }

  return dueIds;
}

String _normalizeTitle(String value) {
  return value.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();
}

class _DashboardTile extends StatelessWidget {
  const _DashboardTile({
    required this.width,
    required this.icon,
    required this.title,
    required this.value,
    this.onTap,
  });

  final double width;
  final IconData icon;
  final String title;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: 148,
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: 28),
                const Spacer(),
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyLarge,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TimedSession {
  const _TimedSession({
    required this.timeRange,
    required this.classroomTitle,
    required this.startMinutes,
    required this.endMinutes,
  });

  final String timeRange;
  final String classroomTitle;
  final int startMinutes;
  final int endMinutes;

  static _TimedSession? fromSession(TimetableSession session) {
    final matches = RegExp(
      r'(\d{1,2})\s*:\s*(\d{2})',
    ).allMatches(session.timeRange).toList();
    if (matches.length < 2) {
      return null;
    }

    final start = _minutesFromMatch(matches[0]);
    final end = _minutesFromMatch(matches[1]);
    if (start == null || end == null || end <= start) {
      return null;
    }

    return _TimedSession(
      timeRange: session.timeRange,
      classroomTitle: session.classroomTitle,
      startMinutes: start,
      endMinutes: end,
    );
  }

  static int? _minutesFromMatch(RegExpMatch match) {
    final hour = int.tryParse(match.group(1) ?? '');
    final minute = int.tryParse(match.group(2) ?? '');
    if (hour == null || minute == null) {
      return null;
    }
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) {
      return null;
    }
    return (hour * 60) + minute;
  }
}
