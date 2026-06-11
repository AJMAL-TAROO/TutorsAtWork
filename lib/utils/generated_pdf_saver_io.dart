import 'dart:io';

import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

Future<String> saveGeneratedPdf({
  required String fileName,
  required List<int> bytes,
}) async {
  final directory = await getApplicationDocumentsDirectory();
  final safeName = _safePdfName(fileName);
  final target = File('${directory.path}${Platform.pathSeparator}$safeName');
  await target.writeAsBytes(bytes, flush: true);
  await OpenFilex.open(target.path);
  return target.path;
}

String _safePdfName(String fileName) {
  final cleaned = fileName
      .replaceAll(RegExp(r'[\\/:*?"<>|]+'), '-')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  final name = cleaned.isEmpty ? 'Generated Exam Paper' : cleaned;
  return name.toLowerCase().endsWith('.pdf') ? name : '$name.pdf';
}
