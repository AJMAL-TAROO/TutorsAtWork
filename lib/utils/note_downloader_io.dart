import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

import '../models/note_file.dart';

Future<void> downloadNote(NoteFile note) async {
  final directory = await getApplicationDocumentsDirectory();
  final target = File('${directory.path}${Platform.pathSeparator}${note.name}');
  final bytes = await FirebaseStorage.instance
      .refFromURL(note.link)
      .getData(100 * 1024 * 1024);

  if (bytes == null || bytes.isEmpty) {
    throw StateError('Firebase returned an empty file.');
  }

  await target.writeAsBytes(bytes, flush: true);
  await OpenFilex.open(target.path);
}
