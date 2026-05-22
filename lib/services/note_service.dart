import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';

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
    final snapshot = await _databaseService.notesFolder(storageFolder).get();
    return _notesFromSnapshotValue(snapshot.value);
  }

  @override
  Stream<List<NoteFile>> watchNotesForFolder(String storageFolder) {
    return _databaseService.notesFolder(storageFolder).onValue.map((event) {
      return _notesFromSnapshotValue(event.snapshot.value);
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
    final storageRef = _storageService.noteFile(storageFolder, noteId);
    final metadata = SettableMetadata(
      contentDisposition: 'inline; filename="${file.name}"',
      contentType: _contentTypeForFileName(file.name),
    );

    await storageRef.putData(Uint8List.fromList(bytes), metadata);
    final downloadUrl = await storageRef.getDownloadURL();
    final note = NoteFile(
      id: noteId,
      name: file.name,
      link: downloadUrl,
      createdAt: DateTime.now(),
    );

    await _databaseService.notesFolder(storageFolder).child('$noteId').set({
      'Name': note.name,
      'ID': note.id,
      'Link': note.link,
      'Time': note.createdAt.millisecondsSinceEpoch,
    });
    await _databaseService.noteCounter(classroomId).set(noteId);

    if (uploadedBy.role == UserRole.admin) {
      await _databaseService.admins
          .child(uploadedBy.key)
          .child('LOGS')
          .child('LAST_UPLOAD_NOTES')
          .set({
            'CLASSROOM_ID': classroomId.toString(),
            'TIMESTAMP': DateTime.now().millisecondsSinceEpoch,
            'DATE': DateTime.now().toIso8601String(),
          });
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

    await _databaseService
        .notesFolder(storageFolder)
        .child('${note.id}')
        .update({'Name': trimmedName});
  }

  @override
  Future<void> deleteNote({
    required String storageFolder,
    required NoteFile note,
  }) async {
    try {
      await _storageService.noteFile(storageFolder, note.id).delete();
    } on FirebaseException catch (error) {
      if (error.code != 'object-not-found') {
        rethrow;
      }
    }

    await _databaseService
        .notesFolder(storageFolder)
        .child('${note.id}')
        .remove();
  }

  Future<int> _nextNoteId({
    required int classroomId,
    required String storageFolder,
  }) async {
    final counterSnapshot = await _databaseService
        .noteCounter(classroomId)
        .get();
    final counterValue = counterSnapshot.value;

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
