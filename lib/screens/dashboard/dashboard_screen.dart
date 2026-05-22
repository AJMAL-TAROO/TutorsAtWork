import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../navigation/app_routes.dart';
import '../../providers/auth_provider.dart';
import '../../providers/classrooms_provider.dart';
import '../../widgets/app_shell.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final classrooms = ref.watch(classroomsProvider);

    return AppShell(
      title: 'Dashboard',
      actions: [
        IconButton(
          tooltip: 'Sign out',
          onPressed: () {
            ref.read(currentUserProvider.notifier).clear();
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
            'Your classroom access, notes, timetable, and attendance will live here as features are migrated.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _DashboardTile(
                icon: Icons.school_outlined,
                title: 'Classrooms',
                value: classrooms.maybeWhen(
                  data: (items) => items.length.toString(),
                  orElse: () => '-',
                ),
                onTap: () => context.go(AppRoutes.classrooms),
              ),
              const _DashboardTile(
                icon: Icons.calendar_month_outlined,
                title: 'Timetable',
                value: 'Soon',
              ),
              const _DashboardTile(
                icon: Icons.fact_check_outlined,
                title: 'Attendance',
                value: 'Soon',
              ),
              const _DashboardTile(
                icon: Icons.description_outlined,
                title: 'Exam AI',
                value: 'Future',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DashboardTile extends StatelessWidget {
  const _DashboardTile({
    required this.icon,
    required this.title,
    required this.value,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      height: 132,
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
                Text(value, style: Theme.of(context).textTheme.bodyLarge),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
