import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../navigation/app_routes.dart';

class AppShell extends StatelessWidget {
  const AppShell({
    required this.title,
    required this.child,
    this.actions,
    super.key,
  });

  final String title;
  final Widget child;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: actions,
      ),
      drawer: NavigationDrawer(
        children: [
          const DrawerHeader(
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Text(
                'House Of Tutors',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          NavigationDrawerDestination(
            icon: const Icon(Icons.dashboard_outlined),
            selectedIcon: const Icon(Icons.dashboard),
            label: const Text('Dashboard'),
          ),
          NavigationDrawerDestination(
            icon: const Icon(Icons.school_outlined),
            selectedIcon: const Icon(Icons.school),
            label: const Text('Classrooms'),
          ),
        ],
        selectedIndex: switch (GoRouterState.of(context).uri.path) {
          AppRoutes.classrooms => 1,
          _ => 0,
        },
        onDestinationSelected: (index) {
          Navigator.of(context).pop();
          context.go(index == 0 ? AppRoutes.dashboard : AppRoutes.classrooms);
        },
      ),
      body: SafeArea(child: child),
    );
  }
}
