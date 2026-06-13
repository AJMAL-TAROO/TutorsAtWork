import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/app_user.dart';
import '../../models/classroom.dart';
import '../../navigation/app_routes.dart';
import '../../providers/auth_provider.dart';
import '../../providers/classrooms_provider.dart';
import '../../services/classroom_link_launcher.dart';
import '../../widgets/app_shell.dart';
import '../../widgets/classroom_card.dart';
import '../../widgets/empty_state.dart';

class ClassroomsScreen extends ConsumerWidget {
  const ClassroomsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final classrooms = ref.watch(classroomsProvider);
    final canManage = user?.role == UserRole.admin;

    return AppShell(
      title: 'Classrooms',
      leading: IconButton(
        tooltip: 'Back to dashboard',
        onPressed: () => context.go(AppRoutes.dashboard),
        icon: const Icon(Icons.arrow_back),
      ),
      onBack: () async => context.go(AppRoutes.dashboard),
      floatingActionButton: canManage
          ? FloatingActionButton.extended(
              onPressed: () => _showClassroomForm(context, ref, user!),
              icon: const Icon(Icons.add_home_work_outlined),
              label: const Text('Create classroom'),
            )
          : null,
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
              icon: Icons.school_outlined,
              title: 'No classrooms yet',
              message: 'Assigned classrooms will appear here.',
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(24),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 360,
              mainAxisExtent: 280,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final classroom = items[index];
              return ClassroomCard(
                classroom: classroom,
                onOpen: () => _joinClassroom(context, ref, user, classroom),
                onViewNotes: () {
                  context.go(
                    AppRoutes.notesForClassroom(classroom.id),
                    extra: classroom,
                  );
                },
                onViewHomework: () {
                  context.go(
                    AppRoutes.homeworkForClassroom(classroom.id),
                    extra: classroom,
                  );
                },
                onViewComments: () {
                  context.go(
                    AppRoutes.commentsForClassroom(classroom.id),
                    extra: classroom,
                  );
                },
                onDelete: canManage
                    ? () => _deleteClassroom(context, ref, user!, classroom)
                    : null,
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _showClassroomForm(
    BuildContext context,
    WidgetRef ref,
    AppUser user,
  ) async {
    final draft = await showDialog<ClassroomDraft>(
      context: context,
      builder: (context) => const _ClassroomFormDialog(),
    );
    if (draft == null || !context.mounted) {
      return;
    }

    try {
      final classroom = await ref
          .read(classroomServiceProvider)
          .createClassroom(adminKey: user.key, draft: draft);
      final roomIds = {...user.virtualRoomIds, classroom.id}.toList()..sort();
      await ref
          .read(currentUserProvider.notifier)
          .updateVirtualRoomIds(roomIds);
      ref.invalidate(classroomsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Classroom created.')));
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Classroom creation failed: $error')),
        );
      }
    }
  }

  Future<void> _joinClassroom(
    BuildContext context,
    WidgetRef ref,
    AppUser? user,
    Classroom classroom,
  ) async {
    if (user == null) {
      return;
    }

    try {
      final link = await ref
          .read(classroomServiceProvider)
          .virtualRoomLinkForClassroom(user: user, classroom: classroom);
      if (!context.mounted) {
        return;
      }
      if (link == null || link.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Virtual class link is not configured.'),
          ),
        );
        return;
      }

      await _openClassroomLink(link);
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open classroom: $error')),
        );
      }
    }
  }

  Future<void> _openClassroomLink(String link) async {
    final uri = _normalizedUri(link);
    final launched = await openClassroomLink(uri);
    if (!launched) {
      throw Exception('Could not launch $uri');
    }
  }

  Uri _normalizedUri(String value) {
    final trimmed = value.trim();
    final uri = Uri.parse(trimmed);
    if (uri.hasScheme) {
      return uri;
    }
    return Uri.parse('https://$trimmed');
  }

  Future<void> _deleteClassroom(
    BuildContext context,
    WidgetRef ref,
    AppUser user,
    Classroom classroom,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete classroom'),
        content: Text(
          'Delete ${classroom.title}? This removes the classroom, its comments, notes, homework, and student assignments for this classroom.',
        ),
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
          .read(classroomServiceProvider)
          .deleteClassroom(adminKey: user.key, classroom: classroom);
      final roomIds =
          user.virtualRoomIds.where((roomId) => roomId != classroom.id).toList()
            ..sort();
      await ref
          .read(currentUserProvider.notifier)
          .updateVirtualRoomIds(roomIds);
      ref.invalidate(classroomsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Classroom deleted.')));
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Classroom delete failed: $error')),
        );
      }
    }
  }
}

class _ClassroomFormDialog extends StatefulWidget {
  const _ClassroomFormDialog();

  @override
  State<_ClassroomFormDialog> createState() => _ClassroomFormDialogState();
}

class _ClassroomFormDialogState extends State<_ClassroomFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create classroom'),
      content: SizedBox(
        width: 520,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    prefixIcon: Icon(Icons.school_outlined),
                  ),
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
          icon: const Icon(Icons.add_home_work_outlined),
          label: const Text('Create'),
        ),
      ],
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    Navigator.of(
      context,
    ).pop(ClassroomDraft(title: _titleController.text.trim()));
  }
}
