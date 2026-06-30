import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/app_config.dart';
import '../../models/app_user.dart';
import '../../navigation/app_routes.dart';
import '../../providers/auth_provider.dart';
import '../../utils/validators.dart';
import '../../widgets/required_update_gate.dart';
import '../../widgets/account_approval_dialog.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  UserRole _role = UserRole.student;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSubmitting = true);
    final authService = ref.read(authServiceProvider);
    final user = await authService.signIn(
      email: _emailController.text,
      password: _passwordController.text,
      role: _role,
    );

    if (!mounted) {
      return;
    }

    setState(() => _isSubmitting = false);

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to sign in with those details.')),
      );
      return;
    }

    if (user.isAccessRestricted) {
      await showAccountApprovalDialog(context, user);
      return;
    }

    await ref.read(currentUserProvider.notifier).setUser(user);
    if (!mounted) {
      return;
    }
    context.go(AppRoutes.dashboard);
  }

  Future<void> _openExternal(String url) async {
    final uri = Uri.parse(url);
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open that link.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return RequiredUpdateGate(
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'TutorsAtWork',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 24),
                          SegmentedButton<UserRole>(
                            segments: const [
                              ButtonSegment(
                                value: UserRole.student,
                                icon: Icon(Icons.person_outline),
                                label: Text('Student'),
                              ),
                              ButtonSegment(
                                value: UserRole.admin,
                                icon: Icon(Icons.admin_panel_settings_outlined),
                                label: Text('Admin'),
                              ),
                            ],
                            selected: {_role},
                            onSelectionChanged: (selection) {
                              setState(() => _role = selection.first);
                            },
                          ),
                          const SizedBox(height: 24),
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              prefixIcon: Icon(Icons.email_outlined),
                            ),
                            validator: Validators.requiredEmail,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: true,
                            decoration: const InputDecoration(
                              labelText: 'Password',
                              prefixIcon: Icon(Icons.lock_outline),
                            ),
                            validator: Validators.requiredPassword,
                            onFieldSubmitted: (_) => _submit(),
                          ),
                          const SizedBox(height: 24),
                          FilledButton.icon(
                            onPressed: _isSubmitting ? null : _submit,
                            icon: _isSubmitting
                                ? const SizedBox.square(
                                    dimension: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.login),
                            label: const Text('Sign in'),
                          ),
                          if (kIsWeb) ...[
                            const SizedBox(height: 16),
                            const Divider(),
                            const SizedBox(height: 8),
                            TextButton.icon(
                              onPressed: () =>
                                  _openExternal(AppConfig.downloadPageUrl),
                              icon: const Icon(Icons.download_outlined),
                              label: const Text('Get Windows or Android app'),
                            ),
                            TextButton.icon(
                              onPressed: () =>
                                  _openExternal(AppConfig.supportPageUrl),
                              icon: const Icon(Icons.support_agent_outlined),
                              label: const Text('Contact support'),
                            ),
                            TextButton.icon(
                              onPressed: () =>
                                  _openExternal(AppConfig.privacyPolicyUrl),
                              icon: const Icon(Icons.privacy_tip_outlined),
                              label: const Text('Privacy Policy'),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
