import 'package:flutter/material.dart';

class ExamAiWebView extends StatelessWidget {
  const ExamAiWebView({required this.uri, super.key});

  final Uri uri;

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Open Exam AI from the installed TAW app.'),
    );
  }
}
