import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/app_user.dart';
import '../../models/attendance_record.dart';
import '../../models/classroom.dart';
import '../../models/student.dart';
import '../../navigation/app_routes.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/classrooms_provider.dart';
import '../../widgets/app_shell.dart';
import '../../widgets/empty_state.dart';

class AttendanceScreen extends ConsumerStatefulWidget {
  const AttendanceScreen({super.key});

  @override
  ConsumerState<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends ConsumerState<AttendanceScreen> {
  DateTime _selectedDate = DateTime.now();
  Classroom? _selectedClassroom;
  List<Student> _students = const [];
  Map<String, AttendanceStatus> _statuses = {};
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final classrooms = ref.watch(classroomsProvider);
    final canManage = user?.role == UserRole.admin;

    return AppShell(
      title: 'Attendance',
      leading: IconButton(
        tooltip: 'Back to dashboard',
        onPressed: () => context.go(AppRoutes.dashboard),
        icon: const Icon(Icons.arrow_back),
      ),
      onBack: () async => context.go(AppRoutes.dashboard),
      child: classrooms.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => EmptyState(
          icon: Icons.error_outline,
          title: 'Could not load classrooms',
          message: error.toString(),
        ),
        data: (items) {
          if (items.isEmpty) {
            return const EmptyState(
              icon: Icons.fact_check_outlined,
              title: 'No classrooms',
              message: 'Attendance needs at least one assigned classroom.',
            );
          }
          _selectedClassroom ??= items.first;

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Wrap(
                spacing: 16,
                runSpacing: 16,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  SizedBox(
                    width: 320,
                    child: DropdownButtonFormField<Classroom>(
                      initialValue: _selectedClassroom,
                      decoration: const InputDecoration(labelText: 'Classroom'),
                      items: [
                        for (final classroom in items)
                          DropdownMenuItem(
                            value: classroom,
                            child: Text(classroom.title),
                          ),
                      ],
                      onChanged: (classroom) {
                        setState(() {
                          _selectedClassroom = classroom;
                          _students = const [];
                          _statuses = {};
                        });
                        _loadAttendance(user);
                      },
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime(DateTime.now().year - 5),
                        lastDate: DateTime(DateTime.now().year + 1),
                      );
                      if (picked != null) {
                        setState(() => _selectedDate = picked);
                        _loadAttendance(user);
                      }
                    },
                    icon: const Icon(Icons.calendar_month_outlined),
                    label: Text(_formatDate(_selectedDate)),
                  ),
                  FilledButton.icon(
                    onPressed: _isLoading ? null : () => _loadAttendance(user),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Load'),
                  ),
                  if (canManage)
                    FilledButton.icon(
                      onPressed: _students.isEmpty || _isLoading
                          ? null
                          : () => _saveAttendance(user!),
                      icon: const Icon(Icons.save_outlined),
                      label: const Text('Save'),
                    ),
                  if (canManage)
                    OutlinedButton.icon(
                      onPressed: _students.isEmpty || _isLoading
                          ? null
                          : () => _deleteAttendance(user!),
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Clear day'),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else if (_students.isEmpty)
                const EmptyState(
                  icon: Icons.people_outline,
                  title: 'Load attendance',
                  message: 'Select a classroom and date to mark attendance.',
                )
              else
                _AttendanceTable(
                  students: _students,
                  statuses: _statuses,
                  canManage: canManage,
                  onChanged: (studentKey, status) {
                    setState(() {
                      _statuses = {..._statuses, studentKey: status};
                    });
                  },
                ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _loadAttendance(AppUser? user) async {
    final classroom = _selectedClassroom;
    if (user == null || classroom == null) {
      return;
    }

    setState(() => _isLoading = true);
    try {
      final studentsFuture = ref
          .read(studentServiceProvider)
          .studentsForClassroom(classroom.id);
      final recordsFuture = ref
          .read(attendanceServiceProvider)
          .attendanceForDate(
            date: _selectedDate,
            adminKey: user.key,
            classroomId: classroom.id,
          );
      final results = await Future.wait([studentsFuture, recordsFuture]);
      final students = results[0] as List<Student>;
      final records = results[1] as Map<String, AttendanceRecord>;
      if (!mounted) {
        return;
      }
      setState(() {
        _students = students;
        _statuses = {
          for (final entry in records.entries) entry.key: entry.value.status,
        };
      });
    } catch (error) {
      if (mounted) {
        _showError('Could not load attendance', error);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveAttendance(AppUser user) async {
    final classroom = _selectedClassroom;
    if (classroom == null) {
      return;
    }
    final records = _students
        .where((student) => _statuses.containsKey(student.key))
        .map(
          (student) => AttendanceRecord(
            studentKey: student.key,
            fullName: student.fullName,
            status: _statuses[student.key]!,
          ),
        );

    try {
      await ref
          .read(attendanceServiceProvider)
          .saveAttendance(
            date: _selectedDate,
            adminKey: user.key,
            classroomId: classroom.id,
            records: records,
          );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Attendance saved.')));
      }
    } catch (error) {
      if (mounted) _showError('Save failed', error);
    }
  }

  Future<void> _deleteAttendance(AppUser user) async {
    final classroom = _selectedClassroom;
    if (classroom == null) {
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear attendance'),
        content: Text(
          'Clear attendance for ${classroom.title} on ${_formatDate(_selectedDate)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }
    try {
      await ref
          .read(attendanceServiceProvider)
          .deleteAttendance(
            date: _selectedDate,
            adminKey: user.key,
            classroomId: classroom.id,
          );
      setState(() => _statuses = {});
    } catch (error) {
      if (mounted) _showError('Clear failed', error);
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  void _showError(String title, Object error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$title: $error'),
        duration: const Duration(seconds: 8),
      ),
    );
  }
}

class _AttendanceTable extends StatelessWidget {
  const _AttendanceTable({
    required this.students,
    required this.statuses,
    required this.canManage,
    required this.onChanged,
  });

  final List<Student> students;
  final Map<String, AttendanceStatus> statuses;
  final bool canManage;
  final void Function(String studentKey, AttendanceStatus status) onChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: students.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final student = students[index];
          final status = statuses[student.key];
          return _AttendanceRow(
            student: student,
            status: status,
            canManage: canManage,
            onChanged: onChanged,
          );
        },
      ),
    );
  }
}

class _AttendanceRow extends StatelessWidget {
  const _AttendanceRow({
    required this.student,
    required this.status,
    required this.canManage,
    required this.onChanged,
  });

  final Student student;
  final AttendanceStatus? status;
  final bool canManage;
  final void Function(String studentKey, AttendanceStatus status) onChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 560;
        final details = Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 2),
              child: Icon(Icons.person_outline),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    student.fullName,
                    style: Theme.of(context).textTheme.titleMedium,
                    overflow: TextOverflow.ellipsis,
                    maxLines: isCompact ? 2 : 1,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    student.email.isEmpty ? student.key : student.email,
                    style: Theme.of(context).textTheme.bodySmall,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ],
              ),
            ),
          ],
        );
        final control = _AttendanceStatusControl(
          status: status,
          canManage: canManage,
          onChanged: (value) => onChanged(student.key, value),
        );

        return Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isCompact ? 12 : 16,
            vertical: 12,
          ),
          child: isCompact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [details, const SizedBox(height: 12), control],
                )
              : Row(
                  children: [
                    Expanded(child: details),
                    const SizedBox(width: 16),
                    control,
                  ],
                ),
        );
      },
    );
  }
}

class _AttendanceStatusControl extends StatelessWidget {
  const _AttendanceStatusControl({
    required this.status,
    required this.canManage,
    required this.onChanged,
  });

  final AttendanceStatus? status;
  final bool canManage;
  final ValueChanged<AttendanceStatus> onChanged;

  @override
  Widget build(BuildContext context) {
    if (!canManage) {
      return Chip(
        label: Text(status?.databaseValue.toUpperCase() ?? 'NOT MARKED'),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SegmentedButton<AttendanceStatus>(
        selected: status == null ? const {} : {status!},
        emptySelectionAllowed: true,
        segments: const [
          ButtonSegment(
            value: AttendanceStatus.present,
            label: Text('Present'),
            icon: Icon(Icons.check_circle_outline),
          ),
          ButtonSegment(
            value: AttendanceStatus.absent,
            label: Text('Absent'),
            icon: Icon(Icons.cancel_outlined),
          ),
        ],
        onSelectionChanged: (selection) {
          if (selection.isNotEmpty) {
            onChanged(selection.first);
          }
        },
      ),
    );
  }
}
