import 'exam_ai_window_launcher_stub.dart'
    if (dart.library.io) 'exam_ai_window_launcher_io.dart'
    if (dart.library.html) 'exam_ai_window_launcher_web.dart';

Future<bool> openExamAiWindow(Uri uri) {
  return openExamAiWindowForPlatform(uri);
}
