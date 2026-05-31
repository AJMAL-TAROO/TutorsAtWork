import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/app_user.dart';
import '../../models/classroom.dart';
import '../../models/student.dart';
import '../../navigation/app_routes.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/classrooms_provider.dart';
import '../../providers/students_provider.dart';
import '../../widgets/app_shell.dart';
import '../../widgets/empty_state.dart';

class StudentsScreen extends ConsumerWidget {
  const StudentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final students = ref.watch(studentsProvider);
    final classrooms = ref.watch(classroomsProvider);
    final canManage = user?.role == UserRole.admin;

    return AppShell(
      title: 'Students',
      leading: IconButton(
        tooltip: 'Back to dashboard',
        onPressed: () => context.go(AppRoutes.dashboard),
        icon: const Icon(Icons.arrow_back),
      ),
      onBack: () async => context.go(AppRoutes.dashboard),
      floatingActionButton: canManage
          ? FloatingActionButton.extended(
              onPressed: () => _showStudentForm(context, ref, user!),
              icon: const Icon(Icons.person_add_alt_1),
              label: const Text('Add student'),
            )
          : null,
      child: students.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => EmptyState(
          icon: Icons.error_outline,
          title: 'Could not load students',
          message: error.toString(),
        ),
        data: (items) {
          if (!canManage) {
            return const EmptyState(
              icon: Icons.lock_outline,
              title: 'Admin only',
              message: 'Student management is available for admin accounts.',
            );
          }
          if (items.isEmpty) {
            return const EmptyState(
              icon: Icons.people_outline,
              title: 'No students yet',
              message: 'Create a student to start assigning classrooms.',
            );
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              final isCompact = constraints.maxWidth < 720;
              return ListView.separated(
                padding: EdgeInsets.fromLTRB(
                  isCompact ? 12 : 24,
                  isCompact ? 12 : 24,
                  isCompact ? 12 : 24,
                  96,
                ),
                itemCount: items.length,
                separatorBuilder: (context, index) =>
                    SizedBox(height: isCompact ? 10 : 12),
                itemBuilder: (context, index) {
                  final student = items[index];
                  return _StudentCard(
                    student: student,
                    classrooms: classrooms.asData?.value ?? const [],
                    isCompact: isCompact,
                    onEdit: () =>
                        _showStudentForm(context, ref, user!, student: student),
                    onDelete: () =>
                        _deleteStudent(context, ref, user!, student),
                    onAssign: () => _assignClassroom(context, ref, student),
                    onRemove: () => _removeClassroom(context, ref, student),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _showStudentForm(
    BuildContext context,
    WidgetRef ref,
    AppUser user, {
    Student? student,
  }) async {
    final draft = await showDialog<StudentDraft>(
      context: context,
      builder: (context) => _StudentFormDialog(student: student),
    );
    if (draft == null || !context.mounted) {
      return;
    }

    try {
      final service = ref.read(studentServiceProvider);
      if (student == null) {
        await service.createStudent(adminKey: user.key, draft: draft);
      } else {
        await service.updateStudent(student: student, draft: draft);
      }
      ref.invalidate(studentsProvider);
      if (context.mounted) {
        _showSnack(
          context,
          student == null ? 'Student created.' : 'Student updated.',
        );
      }
    } catch (error) {
      if (context.mounted) _showSnack(context, 'Student save failed: $error');
    }
  }

  Future<void> _deleteStudent(
    BuildContext context,
    WidgetRef ref,
    AppUser user,
    Student student,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete student'),
        content: Text('Delete ${student.fullName}? This cannot be undone.'),
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
    if (confirmed != true || !context.mounted) {
      return;
    }

    try {
      await ref
          .read(studentServiceProvider)
          .deleteStudent(adminKey: user.key, student: student);
      ref.invalidate(studentsProvider);
      if (context.mounted) _showSnack(context, 'Student deleted.');
    } catch (error) {
      if (context.mounted) _showSnack(context, 'Delete failed: $error');
    }
  }

  Future<void> _assignClassroom(
    BuildContext context,
    WidgetRef ref,
    Student student,
  ) async {
    final classrooms = ref.read(classroomsProvider).asData?.value ?? const [];
    final available = classrooms
        .where((classroom) => !student.virtualRoomIds.contains(classroom.id))
        .toList();
    final classroom = await _selectClassroom(
      context: context,
      title: 'Assign classroom',
      classrooms: available,
      emptyMessage: 'This student is already assigned to every classroom.',
    );
    if (classroom == null || !context.mounted) {
      return;
    }

    try {
      await ref
          .read(studentServiceProvider)
          .assignStudentToClassroom(
            student: student,
            classroomId: classroom.id,
          );
      ref.invalidate(studentsProvider);
      if (context.mounted) _showSnack(context, 'Classroom assigned.');
    } catch (error) {
      if (context.mounted) _showSnack(context, 'Assign failed: $error');
    }
  }

  Future<void> _removeClassroom(
    BuildContext context,
    WidgetRef ref,
    Student student,
  ) async {
    final classrooms = ref.read(classroomsProvider).asData?.value ?? const [];
    final assigned = classrooms
        .where((classroom) => student.virtualRoomIds.contains(classroom.id))
        .toList();
    final classroom = await _selectClassroom(
      context: context,
      title: 'Remove classroom',
      classrooms: assigned,
      emptyMessage: 'This student is not assigned to a classroom.',
    );
    if (classroom == null || !context.mounted) {
      return;
    }

    try {
      await ref
          .read(studentServiceProvider)
          .removeStudentFromClassroom(
            student: student,
            classroomId: classroom.id,
          );
      ref.invalidate(studentsProvider);
      if (context.mounted) _showSnack(context, 'Classroom removed.');
    } catch (error) {
      if (context.mounted) _showSnack(context, 'Remove failed: $error');
    }
  }

  Future<Classroom?> _selectClassroom({
    required BuildContext context,
    required String title,
    required List<Classroom> classrooms,
    required String emptyMessage,
  }) {
    return showDialog<Classroom>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: 420,
          child: classrooms.isEmpty
              ? Text(emptyMessage)
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: classrooms.length,
                  itemBuilder: (context, index) {
                    final classroom = classrooms[index];
                    return ListTile(
                      leading: const Icon(Icons.school_outlined),
                      title: Text(classroom.title),
                      subtitle: Text('Classroom ${classroom.id}'),
                      onTap: () => Navigator.of(context).pop(classroom),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 4)),
    );
  }
}

class _StudentCard extends StatelessWidget {
  const _StudentCard({
    required this.student,
    required this.classrooms,
    required this.isCompact,
    required this.onEdit,
    required this.onDelete,
    required this.onAssign,
    required this.onRemove,
  });

  final Student student;
  final List<Classroom> classrooms;
  final bool isCompact;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onAssign;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final assignedClassrooms = classrooms
        .where((classroom) => student.virtualRoomIds.contains(classroom.id))
        .toList();

    return Card(
      child: Padding(
        padding: EdgeInsets.all(isCompact ? 12 : 16),
        child: isCompact
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _StudentIdentity(student: student),
                  const SizedBox(height: 12),
                  _StudentDetails(
                    student: student,
                    assignedClassrooms: assignedClassrooms,
                  ),
                  const SizedBox(height: 12),
                  _StudentActions(
                    isCompact: true,
                    onEdit: onEdit,
                    onDelete: onDelete,
                    onAssign: onAssign,
                    onRemove: onRemove,
                  ),
                ],
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 2, child: _StudentIdentity(student: student)),
                  const SizedBox(width: 20),
                  Expanded(
                    flex: 3,
                    child: _StudentDetails(
                      student: student,
                      assignedClassrooms: assignedClassrooms,
                    ),
                  ),
                  const SizedBox(width: 20),
                  _StudentActions(
                    isCompact: false,
                    onEdit: onEdit,
                    onDelete: onDelete,
                    onAssign: onAssign,
                    onRemove: onRemove,
                  ),
                ],
              ),
      ),
    );
  }
}

class _StudentIdentity extends StatelessWidget {
  const _StudentIdentity({required this.student});

  final Student student;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          child: Text(
            student.fullName.trim().isEmpty
                ? '?'
                : student.fullName.characters.first.toUpperCase(),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                student.fullName,
                style: Theme.of(context).textTheme.titleMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(student.email, maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Text(student.key, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ],
    );
  }
}

class _StudentDetails extends StatelessWidget {
  const _StudentDetails({
    required this.student,
    required this.assignedClassrooms,
  });

  final Student student;
  final List<Classroom> assignedClassrooms;

  @override
  Widget build(BuildContext context) {
    final roomText = assignedClassrooms.isEmpty
        ? 'No classrooms assigned'
        : assignedClassrooms.map((classroom) => classroom.title).join(', ');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Phone: ${student.telephone}'),
        Text('Responsible: ${student.responsibleParty}'),
        Text('Responsible phone: ${student.responsiblePartyTelephone}'),
        const SizedBox(height: 8),
        Text(
          roomText,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}

class _StudentActions extends StatelessWidget {
  const _StudentActions({
    required this.isCompact,
    required this.onEdit,
    required this.onDelete,
    required this.onAssign,
    required this.onRemove,
  });

  final bool isCompact;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onAssign;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final buttons = [
      IconButton.filledTonal(
        tooltip: 'Edit student',
        onPressed: onEdit,
        icon: const Icon(Icons.edit_outlined),
      ),
      IconButton.filledTonal(
        tooltip: 'Assign classroom',
        onPressed: onAssign,
        icon: const Icon(Icons.add_home_work_outlined),
      ),
      IconButton.filledTonal(
        tooltip: 'Remove classroom',
        onPressed: onRemove,
        icon: const Icon(Icons.remove_circle_outline),
      ),
      IconButton.filledTonal(
        tooltip: 'Delete student',
        onPressed: onDelete,
        icon: const Icon(Icons.delete_outline),
      ),
    ];

    return isCompact
        ? Wrap(spacing: 8, runSpacing: 8, children: buttons)
        : Column(mainAxisSize: MainAxisSize.min, children: buttons);
  }
}

class _StudentFormDialog extends StatefulWidget {
  const _StudentFormDialog({this.student});

  final Student? student;

  @override
  State<_StudentFormDialog> createState() => _StudentFormDialogState();
}

class _StudentFormDialogState extends State<_StudentFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _fullNameController;
  late final TextEditingController _telephoneController;
  late final TextEditingController _responsiblePartyController;
  late final TextEditingController _responsiblePartyTelephoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;

  @override
  void initState() {
    super.initState();
    final student = widget.student;
    _fullNameController = TextEditingController(text: student?.fullName ?? '');
    _telephoneController = TextEditingController(
      text: student?.telephone ?? '',
    );
    _responsiblePartyController = TextEditingController(
      text: student?.responsibleParty ?? '',
    );
    _responsiblePartyTelephoneController = TextEditingController(
      text: student?.responsiblePartyTelephone ?? '',
    );
    _emailController = TextEditingController(text: student?.email ?? '');
    _passwordController = TextEditingController(
      text: student?.password ?? _generatePassword(),
    );
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _telephoneController.dispose();
    _responsiblePartyController.dispose();
    _responsiblePartyTelephoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.student != null;
    return AlertDialog(
      title: Text(isEditing ? 'Edit student' : 'Create student'),
      content: SizedBox(
        width: 520,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _requiredField(
                  controller: _fullNameController,
                  label: 'Full name',
                  icon: Icons.person_outline,
                ),
                const SizedBox(height: 12),
                _requiredField(
                  controller: _telephoneController,
                  label: 'Telephone',
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 12),
                _requiredField(
                  controller: _responsiblePartyController,
                  label: 'Responsible party',
                  icon: Icons.supervisor_account_outlined,
                ),
                const SizedBox(height: 12),
                _requiredField(
                  controller: _responsiblePartyTelephoneController,
                  label: 'Responsible party telephone',
                  icon: Icons.contact_phone_outlined,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 12),
                _requiredField(
                  controller: _emailController,
                  label: 'Email',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.password_outlined),
                    suffixIcon: IconButton(
                      tooltip: 'Generate password',
                      onPressed: () {
                        setState(() {
                          _passwordController.text = _generatePassword();
                        });
                      },
                      icon: const Icon(Icons.refresh),
                    ),
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
                  ],
                  validator: _requiredValidator,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: _submit,
          icon: Icon(isEditing ? Icons.save_outlined : Icons.person_add_alt_1),
          label: Text(isEditing ? 'Save' : 'Create'),
        ),
      ],
    );
  }

  Widget _requiredField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
      validator: _requiredValidator,
    );
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Required';
    }
    return null;
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    Navigator.of(context).pop(
      StudentDraft(
        fullName: _fullNameController.text.trim(),
        telephone: _telephoneController.text.trim(),
        responsibleParty: _responsiblePartyController.text.trim(),
        responsiblePartyTelephone: _responsiblePartyTelephoneController.text
            .trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      ),
    );
  }

  String _generatePassword() {
    final random = Random.secure();
    return (100000 + random.nextInt(900000)).toString();
  }
}
