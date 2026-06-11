import 'package:flutter/material.dart';

class ExamAiWebView extends StatelessWidget {
  const ExamAiWebView({
    required this.uri,
    required this.onNativeMessage,
    super.key,
  });

  final Uri uri;
  final Future<Map<String, Object?>> Function(Map<String, Object?> message)
  onNativeMessage;

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Exam AI is not available on this platform.'),
    );
  }
}
