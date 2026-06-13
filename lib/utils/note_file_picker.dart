import 'note_file_picker_stub.dart'
    if (dart.library.html) 'note_file_picker_web.dart'
    if (dart.library.io) 'note_file_picker_io.dart'
    as implementation;

class PickedNoteFile {
  const PickedNoteFile({
    required this.name,
    required this.size,
    required this.bytes,
  });

  final String name;
  final int size;
  final List<int> bytes;
}

Future<PickedNoteFile?> pickNoteFile({List<String>? allowedExtensions}) {
  return implementation.pickNoteFile(allowedExtensions: allowedExtensions);
}
