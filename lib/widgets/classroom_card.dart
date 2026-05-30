import 'package:flutter/material.dart';

import '../models/classroom.dart';

class ClassroomCard extends StatelessWidget {
  const ClassroomCard({
    required this.classroom,
    this.onOpen,
    this.onViewNotes,
    this.onViewComments,
    this.onDelete,
    super.key,
  });

  final Classroom classroom;
  final VoidCallback? onOpen;
  final VoidCallback? onViewNotes;
  final VoidCallback? onViewComments;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: colorScheme.primaryContainer,
                  foregroundColor: colorScheme.onPrimaryContainer,
                  child: Text(classroom.title.characters.first.toUpperCase()),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        classroom.title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text('Classroom ${classroom.id}'),
                    ],
                  ),
                ),
              ],
            ),
            const Spacer(),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: onOpen,
                  icon: const Icon(Icons.video_call_outlined),
                  label: const Text('Join class'),
                ),
                OutlinedButton.icon(
                  onPressed: onViewNotes,
                  icon: const Icon(Icons.folder_copy_outlined),
                  label: const Text('Notes'),
                ),
                OutlinedButton.icon(
                  onPressed: onViewComments,
                  icon: const Icon(Icons.forum_outlined),
                  label: const Text('Comments'),
                ),
                if (onDelete != null)
                  IconButton.filledTonal(
                    tooltip: 'Delete classroom',
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
