import 'dart:async';

import 'package:flutter/material.dart';

class AppShell extends StatelessWidget {
  const AppShell({
    required this.title,
    required this.child,
    this.actions,
    this.leading,
    this.floatingActionButton,
    this.onBack,
    super.key,
  });

  final String title;
  final Widget child;
  final List<Widget>? actions;
  final Widget? leading;
  final Widget? floatingActionButton;
  final Future<void> Function()? onBack;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: onBack == null,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          return;
        }
        unawaited(onBack?.call());
      },
      child: Scaffold(
        appBar: AppBar(title: Text(title), leading: leading, actions: actions),
        body: SafeArea(child: child),
        floatingActionButton: floatingActionButton,
      ),
    );
  }
}
