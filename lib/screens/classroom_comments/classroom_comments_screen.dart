import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/app_user.dart';
import '../../models/classroom_comment.dart';
import '../../navigation/app_routes.dart';
import '../../providers/auth_provider.dart';
import '../../providers/classroom_comments_provider.dart';
import '../../widgets/app_shell.dart';
import '../../widgets/empty_state.dart';

class ClassroomCommentsScreen extends ConsumerWidget {
  const ClassroomCommentsScreen({
    required this.classroomId,
    required this.classroomTitle,
    super.key,
  });

  final int classroomId;
  final String classroomTitle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final comments = ref.watch(classroomCommentsProvider(classroomId));
    final canManage = user?.role == UserRole.admin;

    return AppShell(
      title: 'Comments',
      leading: IconButton(
        tooltip: 'Back to classrooms',
        onPressed: () => context.go(AppRoutes.classrooms),
        icon: const Icon(Icons.arrow_back),
      ),
      onBack: () async => context.go(AppRoutes.classrooms),
      floatingActionButton: canManage
          ? FloatingActionButton.extended(
              onPressed: () => _showCommentForm(context, ref, user!),
              icon: const Icon(Icons.add_comment_outlined),
              label: const Text('Add comment'),
            )
          : null,
      child: comments.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => EmptyState(
          icon: Icons.error_outline,
          title: 'Could not load comments',
          message: error.toString(),
        ),
        data: (items) {
          if (items.isEmpty) {
            return EmptyState(
              icon: Icons.forum_outlined,
              title: 'No comments yet',
              message: canManage
                  ? 'Add the first classroom comment for $classroomTitle.'
                  : 'Classroom comments will appear here.',
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            itemCount: items.length + 1,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              if (index == 0) {
                return _ClassroomHeader(
                  classroomId: classroomId,
                  classroomTitle: classroomTitle,
                  canManage: canManage,
                );
              }
              final comment = items[index - 1];
              return _CommentCard(
                comment: comment,
                canManage: canManage,
                onEdit: () =>
                    _showCommentForm(context, ref, user!, comment: comment),
                onDelete: () => _deleteComment(context, ref, comment),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _showCommentForm(
    BuildContext context,
    WidgetRef ref,
    AppUser user, {
    ClassroomComment? comment,
  }) async {
    final text = await showDialog<String>(
      context: context,
      builder: (context) => _CommentFormDialog(comment: comment),
    );
    if (text == null || !context.mounted) {
      return;
    }

    try {
      final service = ref.read(classroomCommentServiceProvider);
      if (comment == null) {
        await service.addComment(
          classroomId: classroomId,
          email: user.email,
          comment: text,
        );
      } else {
        await service.updateComment(
          classroomId: classroomId,
          commentId: comment.id,
          comment: text,
        );
      }
      ref.invalidate(classroomCommentsProvider(classroomId));
      if (context.mounted) {
        _showSnack(
          context,
          comment == null ? 'Comment added.' : 'Comment updated.',
        );
      }
    } catch (error) {
      if (context.mounted) _showSnack(context, 'Comment save failed: $error');
    }
  }

  Future<void> _deleteComment(
    BuildContext context,
    WidgetRef ref,
    ClassroomComment comment,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete comment'),
        content: const Text('Delete this classroom comment?'),
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
          .read(classroomCommentServiceProvider)
          .deleteComment(classroomId: classroomId, commentId: comment.id);
      ref.invalidate(classroomCommentsProvider(classroomId));
      if (context.mounted) _showSnack(context, 'Comment deleted.');
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

class _ClassroomHeader extends StatelessWidget {
  const _ClassroomHeader({
    required this.classroomId,
    required this.classroomTitle,
    required this.canManage,
  });

  final int classroomId;
  final String classroomTitle;
  final bool canManage;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const CircleAvatar(child: Icon(Icons.school_outlined)),
      title: Text(classroomTitle),
      subtitle: Text(
        canManage
            ? 'Manage comments for Classroom $classroomId'
            : 'View comments for Classroom $classroomId',
      ),
    );
  }
}

class _CommentCard extends StatelessWidget {
  const _CommentCard({
    required this.comment,
    required this.canManage,
    required this.onEdit,
    required this.onDelete,
  });

  final ClassroomComment comment;
  final bool canManage;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    comment.email,
                    style: Theme.of(context).textTheme.labelLarge,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  comment.date,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 12),
            _CommentText(comment.comment),
            if (canManage) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    IconButton.filledTonal(
                      tooltip: 'Edit comment',
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit_outlined),
                    ),
                    IconButton.filledTonal(
                      tooltip: 'Delete comment',
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete_outline),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CommentText extends StatelessWidget {
  const _CommentText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final spans = <InlineSpan>[];
    final urlPattern = RegExp(r'https?:\/\/[^\s]+');
    var currentIndex = 0;

    for (final match in urlPattern.allMatches(text)) {
      if (match.start > currentIndex) {
        spans.add(TextSpan(text: text.substring(currentIndex, match.start)));
      }
      final url = match.group(0)!;
      spans.add(
        TextSpan(
          text: url,
          style: TextStyle(color: Theme.of(context).colorScheme.primary),
          recognizer: TapGestureRecognizer()
            ..onTap = () => launchUrl(Uri.parse(url)),
        ),
      );
      currentIndex = match.end;
    }

    if (currentIndex < text.length) {
      spans.add(TextSpan(text: text.substring(currentIndex)));
    }

    return SelectableText.rich(
      TextSpan(
        style: Theme.of(context).textTheme.bodyMedium,
        children: spans.isEmpty ? [TextSpan(text: text)] : spans,
      ),
    );
  }
}

class _CommentFormDialog extends StatefulWidget {
  const _CommentFormDialog({this.comment});

  final ClassroomComment? comment;

  @override
  State<_CommentFormDialog> createState() => _CommentFormDialogState();
}

class _CommentFormDialogState extends State<_CommentFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _commentController;

  @override
  void initState() {
    super.initState();
    _commentController = TextEditingController(
      text: widget.comment?.comment ?? '',
    );
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.comment != null;
    return AlertDialog(
      title: Text(isEditing ? 'Edit comment' : 'Add comment'),
      content: SizedBox(
        width: 520,
        child: Form(
          key: _formKey,
          child: TextFormField(
            controller: _commentController,
            decoration: const InputDecoration(
              labelText: 'Comment',
              alignLabelWithHint: true,
              prefixIcon: Icon(Icons.forum_outlined),
            ),
            minLines: 4,
            maxLines: 8,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Required';
              }
              return null;
            },
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
          icon: Icon(isEditing ? Icons.save_outlined : Icons.add_comment),
          label: Text(isEditing ? 'Save' : 'Add'),
        ),
      ],
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    Navigator.of(context).pop(_commentController.text.trim());
  }
}
