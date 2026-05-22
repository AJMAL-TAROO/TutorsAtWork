import 'dart:typed_data';

import '../models/app_user.dart';
import '../models/note_file.dart';
import '../utils/note_file_picker.dart';
import 'firebase_database_service.dart';
import 'storage_service.dart';

abstract class NoteService {
  Future<List<NoteFile>> notesForFolder(String storageFolder);

  Stream<List<NoteFile>> watchNotesForFolder(String storageFolder);

  Future<NoteFile> uploadNote({
    required int classroomId,
    required String storageFolder,
    required PickedNoteFile file,
    required AppUser uploadedBy,
  });

  Future<void> renameNote({
    required String storageFolder,
    required NoteFile note,
    required String newName,
  });

  Future<void> deleteNote({
    required String storageFolder,
    required NoteFile note,
  });
}

class FirebaseNoteService implements NoteService {
  FirebaseNoteService({
    FirebaseDatabaseService? databaseService,
    StorageService? storageService,
  }) : _databaseService = databaseService ?? FirebaseDatabaseService(),
       _storageService = storageService ?? StorageService();

  final FirebaseDatabaseService _databaseService;
  final StorageService _storageService;

  @override
  Future<List<NoteFile>> notesForFolder(String storageFolder) async {
    final value = await _databaseService.get(
      _databaseService.notesFolder(storageFolder),
    );
    return _notesFromSnapshotValue(value);
  }

  @override
  Stream<List<NoteFile>> watchNotesForFolder(String storageFolder) {
    return _databaseService.watch(storageFolder).map((value) {
      return _notesFromSnapshotValue(value);
    });
  }

  @override
  Future<NoteFile> uploadNote({
    required int classroomId,
    required String storageFolder,
    required PickedNoteFile file,
    required AppUser uploadedBy,
  }) async {
    final bytes = file.bytes;
    if (bytes.isEmpty) {
      throw StateError('Selected file could not be read.');
    }

    final noteId = await _nextNoteId(
      classroomId: classroomId,
      storageFolder: storageFolder,
    );
    final downloadUrl = await _storageService.uploadNoteFile(
      storageFolder: storageFolder,
      noteId: noteId,
      bytes: Uint8List.fromList(bytes),
      fileName: file.name,
      contentType: _contentTypeForFileName(file.name),
    );
    final note = NoteFile(
      id: noteId,
      name: file.name,
      link: downloadUrl,
      createdAt: DateTime.now(),
    );

    await _databaseService.set('$storageFolder/$noteId', {
      'Name': note.name,
      'ID': note.id,
      'Link': note.link,
      'Time': note.createdAt.millisecondsSinceEpoch,
    });
    await _databaseService.set(
      _databaseService.noteCounter(classroomId),
      noteId,
    );

    if (uploadedBy.role == UserRole.admin) {
      await _databaseService.set(
        '${_databaseService.admins}/${uploadedBy.key}/LOGS/LAST_UPLOAD_NOTES',
        {
          'CLASSROOM_ID': classroomId.toString(),
          'TIMESTAMP': DateTime.now().millisecondsSinceEpoch,
          'DATE': DateTime.now().toIso8601String(),
        },
      );
    }

    return note;
  }

  @override
  Future<void> renameNote({
    required String storageFolder,
    required NoteFile note,
    required String newName,
  }) async {
    final trimmedName = newName.trim();
    if (trimmedName.isEmpty) {
      throw StateError('File name cannot be empty.');
    }

    await _databaseService.update('$storageFolder/${note.id}', {
      'Name': trimmedName,
    });
  }

  @override
  Future<void> deleteNote({
    required String storageFolder,
    required NoteFile note,
  }) async {
    await _storageService.deleteNoteFile(storageFolder, note.id);
    await _databaseService.remove('$storageFolder/${note.id}');
  }

  Future<int> _nextNoteId({
    required int classroomId,
    required String storageFolder,
  }) async {
    final counterValue = await _databaseService.get(
      _databaseService.noteCounter(classroomId),
    );

    if (counterValue is int) {
      return counterValue + 1;
    }
    if (counterValue is num) {
      return counterValue.toInt() + 1;
    }

    final existingNotes = await notesForFolder(storageFolder);
    if (existingNotes.isEmpty) {
      return 2;
    }

    return existingNotes
            .map((note) => note.id)
            .reduce((a, b) => a > b ? a : b) +
        1;
  }

  String? _contentTypeForFileName(String fileName) {
    final parts = fileName.split('.');
    if (parts.length < 2) {
      return null;
    }

    final extension = parts.last.toLowerCase();
    return switch (extension) {
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'gif' => 'image/gif',
      'pdf' => 'application/pdf',
      'txt' => 'text/plain',
      'mp4' => 'video/mp4',
      'mov' => 'video/quicktime',
      'doc' => 'application/msword',
      'docx' =>
        'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'ppt' => 'application/vnd.ms-powerpoint',
      'pptx' =>
        'application/vnd.openxmlformats-officedocument.presentationml.presentation',
      'zip' => 'application/zip',
      _ => null,
    };
  }

  List<NoteFile> _notesFromSnapshotValue(Object? value) {
    final notes = <NoteFile>[];
    for (final item in _noteItemsFromSnapshotValue(value)) {
      notes.add(NoteFile.fromRealtimeDatabase(item));
    }
    notes.sort((left, right) => right.id.compareTo(left.id));
    return notes;
  }

  Iterable<Map<dynamic, dynamic>> _noteItemsFromSnapshotValue(
    Object? value,
  ) sync* {
    if (value is Map) {
      for (final item in value.values) {
        if (item is Map) {
          yield item;
        }
      }
      return;
    }

    if (value is List) {
      for (final item in value) {
        if (item is Map) {
          yield item;
        }
      }
    }
  }
}
