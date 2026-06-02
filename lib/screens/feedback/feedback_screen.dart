import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/app_user.dart';
import '../../models/student.dart';
import '../../models/student_feedback.dart';
import '../../navigation/app_routes.dart';
import '../../providers/auth_provider.dart';
import '../../providers/student_feedback_provider.dart';
import '../../providers/students_provider.dart';
import '../../widgets/app_shell.dart';
import '../../widgets/empty_state.dart';

class FeedbackScreen extends ConsumerWidget {
  const FeedbackScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final feedback = ref.watch(studentFeedbackProvider);
    final isTutor = user?.role == UserRole.admin;
    final students = isTutor ? ref.watch(studentsProvider) : null;
    final studentItems =
        students?.maybeWhen(
          data: (items) => items,
          orElse: () => const <Student>[],
        ) ??
        const <Student>[];
    final studentsLoading =
        students?.maybeWhen(loading: () => true, orElse: () => false) ?? false;

    return AppShell(
      title: 'Feedback',
      leading: IconButton(
        tooltip: 'Back to dashboard',
        onPressed: () => context.go(AppRoutes.dashboard),
        icon: const Icon(Icons.arrow_back),
      ),
      onBack: () async => context.go(AppRoutes.dashboard),
      floatingActionButton: isTutor
          ? FloatingActionButton.extended(
              onPressed: () {
                if (studentsLoading) {
                  _showSnack(context, 'Students are still loading.');
                  return;
                }
                _showFeedbackForm(context, ref, user!, students: studentItems);
              },
              icon: const Icon(Icons.rate_review_outlined),
              label: const Text('Send feedback'),
            )
          : null,
      child: feedback.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => EmptyState(
          icon: Icons.error_outline,
          title: 'Could not load feedback',
          message: error.toString(),
        ),
        data: (items) {
          if (items.isEmpty) {
            return EmptyState(
              icon: Icons.rate_review_outlined,
              title: isTutor ? 'No feedback sent' : 'No feedback yet',
              message: isTutor
                  ? 'Send feedback to a student and it will appear here.'
                  : 'Feedback from your tutor will appear here.',
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
                  final item = items[index];
                  final canManage =
                      user?.role == UserRole.admin &&
                      item.tutorKey == user?.key;
                  return _FeedbackCard(
                    feedback: item,
                    isTutorView: isTutor,
                    canManage: canManage,
                    onEdit: () =>
                        _showFeedbackForm(context, ref, user!, feedback: item),
                    onDelete: () => _deleteFeedback(context, ref, user!, item),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _showFeedbackForm(
    BuildContext context,
    WidgetRef ref,
    AppUser user, {
    List<Student> students = const <Student>[],
    StudentFeedback? feedback,
  }) async {
    if (user.role != UserRole.admin) {
      return;
    }

    final isEditing = feedback != null;
    if (!isEditing && students.isEmpty) {
      _showSnack(context, 'Create or load a student before sending feedback.');
      return;
    }

    final draft = await showDialog<_FeedbackDraft>(
      context: context,
      builder: (context) =>
          _FeedbackFormDialog(students: students, feedback: feedback),
    );
    if (draft == null || !context.mounted) {
      return;
    }

    try {
      final service = ref.read(studentFeedbackServiceProvider);
      if (feedback == null) {
        await service.createFeedback(
          tutor: user,
          student: draft.student!,
          message: draft.message,
        );
      } else {
        await service.updateFeedback(
          tutor: user,
          feedback: feedback,
          message: draft.message,
        );
      }
      ref.invalidate(studentFeedbackProvider);
      if (context.mounted) {
        _showSnack(
          context,
          feedback == null ? 'Feedback sent.' : 'Feedback updated.',
        );
      }
    } catch (error) {
      if (context.mounted) _showSnack(context, 'Feedback save failed: $error');
    }
  }

  Future<void> _deleteFeedback(
    BuildContext context,
    WidgetRef ref,
    AppUser user,
    StudentFeedback feedback,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete feedback'),
        content: Text('Delete feedback for ${feedback.studentName}?'),
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
          .read(studentFeedbackServiceProvider)
          .deleteFeedback(tutor: user, feedback: feedback);
      ref.invalidate(studentFeedbackProvider);
      if (context.mounted) _showSnack(context, 'Feedback deleted.');
    } catch (error) {
      if (context.mounted) _showSnack(context, 'Delete failed: $error');
    }
  }

  void _showSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 4)),
    );
  }
}

class _FeedbackCard extends StatelessWidget {
  const _FeedbackCard({
    required this.feedback,
    required this.isTutorView,
    required this.canManage,
    required this.onEdit,
    required this.onDelete,
  });

  final StudentFeedback feedback;
  final bool isTutorView;
  final bool canManage;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final title = isTutorView ? feedback.studentName : feedback.tutorName;
    final subtitle = isTutorView
        ? 'Student feedback'
        : feedback.tutorEmail.isEmpty
        ? 'Tutor feedback'
        : feedback.tutorEmail;
    final dateLabel = feedback.wasUpdated
        ? '${feedback.date} - edited ${feedback.updatedDate}'
        : feedback.date;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  child: Text(
                    title.trim().isEmpty
                        ? '?'
                        : title.characters.first.toUpperCase(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        dateLabel,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                if (canManage) ...[
                  const SizedBox(width: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      IconButton.filledTonal(
                        tooltip: 'Edit feedback',
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit_outlined),
                      ),
                      IconButton.filledTonal(
                        tooltip: 'Delete feedback',
                        onPressed: onDelete,
                        icon: const Icon(Icons.delete_outline),
                      ),
                    ],
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),
            SelectableText(feedback.message),
          ],
        ),
      ),
    );
  }
}

class _FeedbackFormDialog extends StatefulWidget {
  const _FeedbackFormDialog({required this.students, this.feedback});

  final List<Student> students;
  final StudentFeedback? feedback;

  @override
  State<_FeedbackFormDialog> createState() => _FeedbackFormDialogState();
}

class _FeedbackFormDialogState extends State<_FeedbackFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _messageController;
  Student? _selectedStudent;

  @override
  void initState() {
    super.initState();
    _messageController = TextEditingController(
      text: widget.feedback?.message ?? '',
    );
    if (widget.students.isNotEmpty) {
      _selectedStudent = widget.students.first;
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.feedback != null;
    return AlertDialog(
      title: Text(isEditing ? 'Edit feedback' : 'Send feedback'),
      content: SizedBox(
        width: 560,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isEditing)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.person_outline),
                    title: Text(widget.feedback!.studentName),
                    subtitle: const Text('Student'),
                  )
                else
                  DropdownButtonFormField<Student>(
                    initialValue: _selectedStudent,
                    decoration: const InputDecoration(
                      labelText: 'Student',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    items: [
                      for (final student in widget.students)
                        DropdownMenuItem(
                          value: student,
                          child: Text(student.fullName),
                        ),
                    ],
                    onChanged: (student) {
                      setState(() {
                        _selectedStudent = student;
                      });
                    },
                    validator: (value) {
                      if (value == null) {
                        return 'Required';
                      }
                      return null;
                    },
                  ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _messageController,
                  decoration: const InputDecoration(
                    labelText: 'Feedback',
                    alignLabelWithHint: true,
                    prefixIcon: Icon(Icons.rate_review_outlined),
                  ),
                  minLines: 5,
                  maxLines: 10,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Required';
                    }
                    return null;
                  },
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
          icon: Icon(isEditing ? Icons.save_outlined : Icons.send_outlined),
          label: Text(isEditing ? 'Save' : 'Send'),
        ),
      ],
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    Navigator.of(context).pop(
      _FeedbackDraft(
        student: _selectedStudent,
        message: _messageController.text.trim(),
      ),
    );
  }
}

class _FeedbackDraft {
  const _FeedbackDraft({required this.student, required this.message});

  final Student? student;
  final String message;
}
