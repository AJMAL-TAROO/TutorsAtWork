import 'package:file_picker/file_picker.dart';

import 'note_file_picker.dart';

Future<PickedNoteFile?> pickNoteFile() async {
  final result = await FilePicker.pickFiles(type: FileType.any, withData: true);
  if (result == null || result.files.isEmpty) {
    return null;
  }

  final file = result.files.single;
  final bytes = file.bytes;
  if (bytes == null) {
    throw StateError('Selected file could not be read.');
  }

  return PickedNoteFile(name: file.name, size: file.size, bytes: bytes);
}
