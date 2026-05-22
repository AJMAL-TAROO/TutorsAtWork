import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/note_file.dart';
import '../services/note_service.dart';

final noteServiceProvider = Provider<NoteService>((ref) {
  return FirebaseNoteService();
});

final notesProvider = StreamProvider.family<List<NoteFile>, String>((
  ref,
  storageFolder,
) {
  final service = ref.watch(noteServiceProvider);
  return service.watchNotesForFolder(storageFolder);
});
