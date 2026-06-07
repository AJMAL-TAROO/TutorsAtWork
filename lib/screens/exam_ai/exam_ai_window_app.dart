import 'package:flutter/material.dart';

import '../../themes/app_theme.dart';
import '../../widgets/exam_ai_web_view.dart';

class ExamAiWindowApp extends StatelessWidget {
  const ExamAiWindowApp({required this.uri, super.key});

  final Uri uri;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TAW Exam AI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      home: Scaffold(
        appBar: AppBar(title: const Text('Exam AI')),
        body: SafeArea(child: ExamAiWebView(uri: uri)),
      ),
    );
  }
}
