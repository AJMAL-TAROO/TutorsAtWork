import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/app_user.dart';
import '../../models/classroom.dart';
import '../../models/timetable_session.dart';
import '../../navigation/app_routes.dart';
import '../../providers/auth_provider.dart';
import '../../providers/classrooms_provider.dart';
import '../../providers/timetable_provider.dart';
import '../../widgets/app_shell.dart';
import '../../widgets/empty_state.dart';

class TimetableScreen extends ConsumerWidget {
  const TimetableScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final sessions = ref.watch(timetableProvider);
    final classrooms = ref.watch(classroomsProvider);
    final classroomItems = classrooms.asData?.value ?? const <Classroom>[];
    final canManage = user?.role == UserRole.admin;

    return AppShell(
      title: 'Timetable',
      leading: IconButton(
        tooltip: 'Back to dashboard',
        onPressed: () => context.go(AppRoutes.dashboard),
        icon: const Icon(Icons.arrow_back),
      ),
      floatingActionButton: canManage
          ? FloatingActionButton.extended(
              onPressed: () => _showSessionDialog(
                context: context,
                ref: ref,
                user: user!,
                classrooms: classroomItems,
              ),
              icon: const Icon(Icons.add),
              label: const Text('Add session'),
            )
          : null,
      child: sessions.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => EmptyState(
          icon: Icons.error_outline,
          title: 'Could not load timetable',
          message: error.toString(),
        ),
        data: (items) {
          if (items.isEmpty) {
            return const EmptyState(
              icon: Icons.calendar_month_outlined,
              title: 'No timetable sessions',
              message: 'Scheduled classes will appear here.',
            );
          }

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              for (var day = 1; day <= 7; day++)
                _DaySection(
                  day: day,
                  sessions: items.where((item) => item.day == day).toList(),
                  canManage: canManage,
                  onEdit: (session) => _showSessionDialog(
                    context: context,
                    ref: ref,
                    user: user!,
                    classrooms: classroomItems,
                    session: session,
                  ),
                  onDelete: (session) =>
                      _deleteSession(context, ref, user!, session),
                ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showSessionDialog({
    required BuildContext context,
    required WidgetRef ref,
    required AppUser user,
    required List<Classroom> classrooms,
    TimetableSession? session,
  }) async {
    final dayOptions = Map.fromEntries(
      List.generate(7, (index) {
        final day = index + 1;
        return MapEntry(day, TimetableSession(day: day, timeRange: '', classroomTitle: '').dayName);
      }),
    );
    final times = List.generate(
      24,
      (index) => '${index.toString().padLeft(2, '0')}:00',
    );

    var selectedDay = session?.day ?? DateTime.now().weekday;
    var selectedClassroomTitle = session?.classroomTitle ??
        (classrooms.isEmpty ? '' : classrooms.first.title);
    var startTime = session?.timeRange.split(' - ').first ?? '08:00';
    var endTime = session?.timeRange.split(' - ').last ?? '09:00';
    final oldSession = session;

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(oldSession == null ? 'Add session' : 'Edit session'),
              content: SizedBox(
                width: 420,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<int>(
                      initialValue: selectedDay,
                      decoration: const InputDecoration(labelText: 'Day'),
                      items: [
                        for (final entry in dayOptions.entries)
                          DropdownMenuItem(
                            value: entry.key,
                            child: Text(entry.value),
                          ),
                      ],
                      onChanged: (value) =>
                          setDialogState(() => selectedDay = value ?? selectedDay),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: selectedClassroomTitle.isEmpty
                          ? null
                          : selectedClassroomTitle,
                      decoration: const InputDecoration(labelText: 'Classroom'),
                      items: [
                        for (final classroom in classrooms)
                          DropdownMenuItem(
                            value: classroom.title,
                            child: Text(classroom.title),
                          ),
                      ],
                      onChanged: (value) => setDialogState(
                        () => selectedClassroomTitle = value ?? '',
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: startTime,
                            decoration: const InputDecoration(labelText: 'Start'),
                            items: [
                              for (final time in times)
                                DropdownMenuItem(value: time, child: Text(time)),
                            ],
                            onChanged: (value) =>
                                setDialogState(() => startTime = value ?? startTime),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: endTime,
                            decoration: const InputDecoration(labelText: 'End'),
                            items: [
                              for (final time in times)
                                DropdownMenuItem(value: time, child: Text(time)),
                            ],
                            onChanged: (value) =>
                                setDialogState(() => endTime = value ?? endTime),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: selectedClassroomTitle.isEmpty
                      ? null
                      : () => Navigator.of(dialogContext).pop(true),
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    if (saved != true || !context.mounted) {
      return;
    }

    final service = ref.read(timetableServiceProvider);
    final newTimeRange = '$startTime - $endTime';
    if (oldSession != null &&
        (oldSession.day != selectedDay || oldSession.timeRange != newTimeRange)) {
      await service.deleteSession(
        adminKey: user.key,
        day: oldSession.day,
        timeRange: oldSession.timeRange,
      );
    }
    await service.upsertSession(
      adminKey: user.key,
      day: selectedDay,
      timeRange: newTimeRange,
      classroomTitle: selectedClassroomTitle,
    );
    ref.invalidate(timetableProvider);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Timetable saved.')),
      );
    }
  }

  Future<void> _deleteSession(
    BuildContext context,
    WidgetRef ref,
    AppUser user,
    TimetableSession session,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete session'),
        content: Text('Delete ${session.timeRange} ${session.classroomTitle}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }
    await ref.read(timetableServiceProvider).deleteSession(
          adminKey: user.key,
          day: session.day,
          timeRange: session.timeRange,
        );
    ref.invalidate(timetableProvider);
  }
}

class _DaySection extends StatelessWidget {
  const _DaySection({
    required this.day,
    required this.sessions,
    required this.canManage,
    required this.onEdit,
    required this.onDelete,
  });

  final int day;
  final List<TimetableSession> sessions;
  final bool canManage;
  final ValueChanged<TimetableSession> onEdit;
  final ValueChanged<TimetableSession> onDelete;

  @override
  Widget build(BuildContext context) {
    final dayName = TimetableSession(day: day, timeRange: '', classroomTitle: '').dayName;
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(dayName, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          if (sessions.isEmpty)
            const Text('No sessions scheduled.')
          else
            for (final session in sessions)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.schedule),
                  title: Text(session.timeRange),
                  subtitle: Text(session.classroomTitle),
                  trailing: canManage
                      ? PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'edit') onEdit(session);
                            if (value == 'delete') onDelete(session);
                          },
                          itemBuilder: (context) => const [
                            PopupMenuItem(value: 'edit', child: Text('Edit')),
                            PopupMenuItem(value: 'delete', child: Text('Delete')),
                          ],
                        )
                      : null,
                ),
              ),
        ],
      ),
    );
  }
}
