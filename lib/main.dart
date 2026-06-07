import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:responsive_framework/responsive_framework.dart';

import 'config/app_config.dart';
import 'config/firebase_bootstrap.dart';
import 'navigation/app_router.dart';
import 'providers/auth_provider.dart';
import 'screens/exam_ai/exam_ai_window_app.dart';
import 'services/session_service.dart';
import 'themes/app_theme.dart';

Future<void> main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

  final examAiUri = _examAiUriFromArgs(args);
  if (examAiUri != null) {
    runApp(ExamAiWindowApp(uri: examAiUri));
    return;
  }

  await FirebaseBootstrap.maybeInitialize();
  final initialUser = await SessionService().loadUser();

  runApp(
    ProviderScope(
      overrides: [initialUserProvider.overrideWithValue(initialUser)],
      child: const TawApp(),
    ),
  );
}

class TawApp extends ConsumerWidget {
  const TawApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      routerConfig: router,
      builder: (context, child) {
        return ResponsiveBreakpoints.builder(
          child: child!,
          breakpoints: const [
            Breakpoint(start: 0, end: 599, name: MOBILE),
            Breakpoint(start: 600, end: 1023, name: TABLET),
            Breakpoint(start: 1024, end: 1919, name: DESKTOP),
            Breakpoint(start: 1920, end: double.infinity, name: '4K'),
          ],
        );
      },
    );
  }
}

Uri? _examAiUriFromArgs(List<String> args) {
  if (!args.contains('--exam-ai-window')) {
    return null;
  }

  for (final arg in args) {
    const prefix = '--exam-ai-url=';
    if (!arg.startsWith(prefix)) {
      continue;
    }
    return Uri.tryParse(arg.substring(prefix.length));
  }

  return null;
}
