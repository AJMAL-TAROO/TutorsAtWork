import 'dart:io';

Future<bool> openExamAiWindowForPlatform(Uri uri) async {
  if (!Platform.isWindows) {
    return false;
  }

  await Process.start(Platform.resolvedExecutable, [
    '--exam-ai-window',
    '--exam-ai-url=${uri.toString()}',
  ], mode: ProcessStartMode.detached);
  return true;
}
