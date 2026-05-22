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
      appBar: AppBar(title: Text(title), actions: actions),
      drawer: NavigationDrawer(
        selectedIndex: switch (GoRouterState.of(context).uri.path) {
          AppRoutes.classrooms => 1,
          _ => 0,
        },
        onDestinationSelected: (index) {
          Navigator.of(context).pop();
          context.go(index == 0 ? AppRoutes.dashboard : AppRoutes.classrooms);
        },
        children: const [
          DrawerHeader(
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Text(
                'House Of Tutors',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          NavigationDrawerDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: Text('Dashboard'),
          ),
          NavigationDrawerDestination(
            icon: Icon(Icons.school_outlined),
            selectedIcon: Icon(Icons.school),
            label: Text('Classrooms'),
          ),
        ],
      ),
      body: SafeArea(child: child),
    );
  }
}
