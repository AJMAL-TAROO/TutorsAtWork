import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/classrooms_provider.dart';
import '../../widgets/app_shell.dart';
import '../../widgets/classroom_card.dart';
import '../../widgets/empty_state.dart';

class ClassroomsScreen extends ConsumerWidget {
  const ClassroomsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final classrooms = ref.watch(classroomsProvider);

    return AppShell(
      title: 'Classrooms',
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
              mainAxisExtent: 260,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final classroom = items[index];
              return ClassroomCard(
                classroom: classroom,
                onOpen: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        classroom.virtualRoomLink == null
                            ? 'Virtual class link is not configured yet.'
                            : 'Ready to open ${classroom.title}.',
                      ),
                    ),
                  );
                },
                onViewNotes: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Notes folder: ${classroom.storageFolder}',
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
