import '../models/note_file.dart';
import 'note_downloader_stub.dart'
    if (dart.library.html) 'note_downloader_web.dart'
    if (dart.library.io) 'note_downloader_io.dart'
    as implementation;

Future<void> downloadNote(NoteFile note) {
  return implementation.downloadNote(note);
}
