import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';

import '../config/firebase_options.dart';

class StorageService {
  StorageService({FirebaseStorage? storage}) : _storage = storage;

  final FirebaseStorage? _storage;

  FirebaseStorage get _storageInstance =>
      _storage ??
      FirebaseStorage.instanceFor(
        bucket: 'gs://${DefaultFirebaseOptions.storageBucket}',
      );

  String classroomNotesFolder(String classroomId) {
    return '${classroomId}_NOTES';
  }

  String noteFile(String storageFolder, int noteId) {
    return '$storageFolder/$noteId';
  }

  String homeworkFolder(int classroomId) => '${classroomId}_HOMEWORK';

  String homeworkFile(int classroomId, int homeworkId) {
    return '${homeworkFolder(classroomId)}/$homeworkId';
  }

  Future<String> uploadNoteFile({
    required String storageFolder,
    required int noteId,
    required List<int> bytes,
    required String fileName,
    required String? contentType,
  }) {
    return _uploadFile(
      objectPath: noteFile(storageFolder, noteId),
      bytes: bytes,
      fileName: fileName,
      contentType: contentType,
    );
  }

  Future<String> _uploadFile({
    required String objectPath,
    required List<int> bytes,
    required String fileName,
    required String? contentType,
  }) async {
    final reference = _storageInstance.ref(objectPath);
    final safeFileName = fileName.replaceAll('"', '');
    final metadata = SettableMetadata(
      contentType: contentType,
      contentDisposition: 'inline; filename="$safeFileName"',
    );

    try {
      await reference.putData(Uint8List.fromList(bytes), metadata);
      return reference.getDownloadURL();
    } on FirebaseException catch (error) {
      throw StateError(
        'Firebase Storage upload failed (${error.code}): '
        '${error.message ?? 'Unknown Firebase error.'}',
      );
    }
  }

  Future<void> deleteNoteFile(String storageFolder, int noteId) {
    return _deleteFile(noteFile(storageFolder, noteId));
  }

  Future<void> _deleteFile(String objectPath) async {
    try {
      await _storageInstance.ref(objectPath).delete();
    } on FirebaseException catch (error) {
      if (error.code == 'object-not-found') {
        return;
      }
      throw StateError(
        'Firebase Storage delete failed (${error.code}): '
        '${error.message ?? 'Unknown Firebase error.'}',
      );
    }
  }

  Future<String> uploadHomeworkFile({
    required int classroomId,
    required int homeworkId,
    required List<int> bytes,
    required String fileName,
    required String? contentType,
  }) {
    return _uploadFile(
      objectPath: homeworkFile(classroomId, homeworkId),
      bytes: bytes,
      fileName: fileName,
      contentType: contentType,
    );
  }

  Future<void> deleteHomeworkFile(int classroomId, int homeworkId) {
    return _deleteFile(homeworkFile(classroomId, homeworkId));
  }
}
