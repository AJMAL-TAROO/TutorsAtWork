import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/app_update.dart';
import '../providers/app_update_provider.dart';
import '../services/app_update_service.dart';

class RequiredUpdateGate extends ConsumerStatefulWidget {
  const RequiredUpdateGate({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<RequiredUpdateGate> createState() => _RequiredUpdateGateState();
}

class _RequiredUpdateGateState extends ConsumerState<RequiredUpdateGate>
    with WidgetsBindingObserver {
  AppUpdate? _requiredUpdate;
  bool _isChecking = false;
  bool _dialogVisible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkForUpdate());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_checkForUpdate());
    }
  }

  Future<void> _checkForUpdate() async {
    if (_isChecking || !mounted) {
      return;
    }
    _isChecking = true;
    try {
      final update = await ref.read(appUpdateServiceProvider).requiredUpdate();
      if (!mounted) {
        return;
      }
      _requiredUpdate = update;
      if (update != null && !_dialogVisible) {
        unawaited(_showRequiredUpdate(update));
      }
    } catch (_) {
      // A failed version check must not prevent normal app use.
    } finally {
      _isChecking = false;
    }
  }

  Future<void> _showRequiredUpdate(AppUpdate update) async {
    _dialogVisible = true;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return PopScope(
          canPop: false,
          child: AlertDialog(
            icon: const Icon(Icons.system_update_alt),
            title: const Text('Update required'),
            content: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TutorsAtWork ${update.version} is now available.',
                    style: Theme.of(dialogContext).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    update.description.isEmpty
                        ? 'Install the latest version to continue using TutorsAtWork.'
                        : update.description,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Installed version: ${AppUpdateService.currentVersion}',
                    style: Theme.of(dialogContext).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            actions: [
              FilledButton.icon(
                onPressed: () => _openUpdateLink(update.link!),
                icon: const Icon(Icons.download),
                label: const Text('Update now'),
              ),
            ],
          ),
        );
      },
    );
    _dialogVisible = false;

    if (mounted && _requiredUpdate != null) {
      unawaited(_showRequiredUpdate(_requiredUpdate!));
    }
  }

  Future<void> _openUpdateLink(Uri link) async {
    final opened = await launchUrl(link, mode: LaunchMode.externalApplication);
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the update link.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
