import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/app_user.dart';
import '../../navigation/app_routes.dart';
import '../../providers/auth_provider.dart';
import '../../providers/exam_ai_provider.dart';
import '../../widgets/app_shell.dart';
import '../../widgets/exam_ai_web_view.dart';

class ExamAiScreen extends ConsumerStatefulWidget {
  const ExamAiScreen({this.initialUrl, super.key});

  final String? initialUrl;

  @override
  ConsumerState<ExamAiScreen> createState() => _ExamAiScreenState();
}

class _ExamAiScreenState extends ConsumerState<ExamAiScreen> {
  Future<Uri>? _sessionUriFuture;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);

    return AppShell(
      title: 'Exam AI',
      leading: IconButton(
        tooltip: 'Back to dashboard',
        onPressed: () => context.go(AppRoutes.dashboard),
        icon: const Icon(Icons.arrow_back),
      ),
      onBack: () async => context.go(AppRoutes.dashboard),
      child: _buildBody(context, user),
    );
  }

  Widget _buildBody(BuildContext context, AppUser? user) {
    if (user == null) {
      return const Center(child: Text('Sign in again to use Exam AI.'));
    }
    if (user.role != UserRole.admin) {
      return const Center(child: Text('Exam AI is available to tutors only.'));
    }

    _sessionUriFuture ??= _createSessionUri(user);

    return FutureBuilder<Uri>(
      future: _sessionUriFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return _ExamAiError(message: snapshot.error.toString());
        }
        return ExamAiWebView(uri: snapshot.data!);
      },
    );
  }

  Future<Uri> _createSessionUri(AppUser user) {
    final url = widget.initialUrl;
    if (url != null && url.trim().isNotEmpty) {
      return Future<Uri>.sync(() => Uri.parse(url));
    }
    return ref.read(examAiServiceProvider).createSessionUri(user);
  }
}

class _ExamAiError extends StatelessWidget {
  const _ExamAiError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.description_outlined,
                size: 56,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'Could not open Exam AI.',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(message, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
