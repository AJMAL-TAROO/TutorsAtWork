import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../navigation/app_routes.dart';

class AppShell extends StatelessWidget {
  const AppShell({
    required this.title,
    required this.child,
    this.actions,
    this.leading,
    this.floatingActionButton,
    super.key,
  });

  final String title;
  final Widget child;
  final List<Widget>? actions;
  final Widget? leading;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title), leading: leading, actions: actions),
      drawer: NavigationDrawer(
        selectedIndex: switch (GoRouterState.of(context).uri.path) {
          AppRoutes.classrooms => 1,
          AppRoutes.students => 2,
          AppRoutes.timetable => 3,
          AppRoutes.attendance => 4,
          _ => 0,
        },
        onDestinationSelected: (index) {
          Navigator.of(context).pop();
          context.go(switch (index) {
            0 => AppRoutes.dashboard,
            1 => AppRoutes.classrooms,
            2 => AppRoutes.students,
            3 => AppRoutes.timetable,
            4 => AppRoutes.attendance,
            _ => AppRoutes.dashboard,
          });
        },
        children: const [
          DrawerHeader(
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Text(
                'TutorsAtWork',
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
          NavigationDrawerDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: Text('Students'),
          ),
          NavigationDrawerDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: Text('Timetable'),
          ),
          NavigationDrawerDestination(
            icon: Icon(Icons.fact_check_outlined),
            selectedIcon: Icon(Icons.fact_check),
            label: Text('Attendance'),
          ),
        ],
      ),
      body: SafeArea(child: child),
      floatingActionButton: floatingActionButton,
    );
  }
}
