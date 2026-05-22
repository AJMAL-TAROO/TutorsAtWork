import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

import '../models/note_file.dart';

Future<void> downloadNote(NoteFile note) async {
  final directory = await getApplicationDocumentsDirectory();
  final target = File('${directory.path}${Platform.pathSeparator}${note.name}');
  final response = await http.get(Uri.parse(note.link));

  if (response.statusCode < 200 || response.statusCode >= 300) {
    throw StateError('Download failed: ${response.statusCode}');
  }
  if (response.bodyBytes.isEmpty) {
    throw StateError('Firebase returned an empty file.');
  }

  await target.writeAsBytes(response.bodyBytes, flush: true);
  await OpenFilex.open(target.path);
}
