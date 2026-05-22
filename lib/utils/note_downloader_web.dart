// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:html' as html;

import '../models/note_file.dart';

Future<void> downloadNote(NoteFile note) async {
  final anchor = html.AnchorElement(href: note.link)
    ..download = note.name
    ..target = '_blank';

  html.document.body?.append(anchor);
  anchor.click();
  anchor.remove();
}
