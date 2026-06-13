// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';

import 'note_file_picker.dart';

Future<PickedNoteFile?> pickNoteFile({List<String>? allowedExtensions}) {
  final completer = Completer<PickedNoteFile?>();
  final input = html.FileUploadInputElement()
    ..accept = allowedExtensions == null
        ? '*/*'
        : allowedExtensions.map((extension) => '.$extension').join(',')
    ..multiple = false;

  input.onChange.first.then((_) {
    final files = input.files;
    if (files == null || files.isEmpty) {
      if (!completer.isCompleted) {
        completer.complete(null);
      }
      return;
    }

    final file = files.first;
    final reader = html.FileReader();

    reader.onError.first.then((_) {
      if (!completer.isCompleted) {
        completer.completeError(StateError('Selected file could not be read.'));
      }
    });

    reader.onLoad.first.then((_) {
      final result = reader.result;
      final bytes = switch (result) {
        ByteBuffer buffer => Uint8List.view(buffer),
        Uint8List list => list,
        _ => throw StateError('Selected file could not be read.'),
      };

      if (!completer.isCompleted) {
        completer.complete(
          PickedNoteFile(name: file.name, size: file.size, bytes: bytes),
        );
      }
    });

    reader.readAsArrayBuffer(file);
  });

  input.click();
  return completer.future;
}
