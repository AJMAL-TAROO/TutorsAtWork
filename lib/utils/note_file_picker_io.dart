import 'package:file_picker/file_picker.dart';

import 'note_file_picker.dart';

Future<PickedNoteFile?> pickNoteFile({List<String>? allowedExtensions}) async {
  final result = await FilePicker.pickFiles(
    type: allowedExtensions == null ? FileType.any : FileType.custom,
    allowedExtensions: allowedExtensions,
    withData: true,
  );
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
