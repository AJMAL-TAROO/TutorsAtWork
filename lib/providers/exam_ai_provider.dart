import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/exam_ai_service.dart';

final examAiServiceProvider = Provider<ExamAiService>((ref) {
  return ExamAiService();
});
