import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/app_user.dart';
import '../navigation/app_routes.dart';
import '../providers/auth_provider.dart';
import 'account_approval_dialog.dart';

class AccountApprovalGate extends ConsumerStatefulWidget {
  const AccountApprovalGate({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<AccountApprovalGate> createState() =>
      _AccountApprovalGateState();
}

class _AccountApprovalGateState extends ConsumerState<AccountApprovalGate> {
  bool _checking = true;
  bool _isCheckingApproval = false;
  bool _isHandlingRestriction = false;
  Timer? _approvalTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _checkApproval();
      if (mounted) {
        _approvalTimer = Timer.periodic(
          const Duration(seconds: 3),
          (_) => _checkApproval(),
        );
      }
    });
  }

  @override
  void dispose() {
    _approvalTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkApproval() async {
    if (_isCheckingApproval || _isHandlingRestriction) {
      return;
    }
    _isCheckingApproval = true;

    final user = ref.read(currentUserProvider);
    if (user == null || user.role != UserRole.admin) {
      if (mounted) {
        setState(() => _checking = false);
      }
      _isCheckingApproval = false;
      return;
    }

    String? status;
    try {
      status = await ref
          .read(authServiceProvider)
          .adminApprovalStatus(user.key);
    } catch (_) {
      status = user.approvalStatus;
    }

    if (!mounted) {
      _isCheckingApproval = false;
      return;
    }

    final refreshedUser = user.withApprovalStatus(status);
    if (!refreshedUser.isAccessRestricted) {
      if (_checking) {
        setState(() => _checking = false);
      }
      _isCheckingApproval = false;
      return;
    }

    _isHandlingRestriction = true;
    _isCheckingApproval = false;
    await showAccountApprovalDialog(context, refreshedUser);
    await ref.read(currentUserProvider.notifier).clear();
    if (mounted) {
      context.go(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return widget.child;
  }
}
