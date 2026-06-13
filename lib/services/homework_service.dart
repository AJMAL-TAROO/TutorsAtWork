import 'dart:typed_data';

import '../models/app_user.dart';
import '../models/homework_file.dart';
import '../utils/note_file_picker.dart';
import 'firebase_database_service.dart';
import 'storage_service.dart';

abstract class HomeworkService {
  Stream<List<HomeworkFile>> watchHomework({
    required int classroomId,
    required AppUser user,
  });

  Future<HomeworkFile> uploadHomework({
    required int classroomId,
    required PickedNoteFile file,
    required AppUser uploadedBy,
  });

  Future<void> renameHomework({
    required int classroomId,
    required HomeworkFile homework,
    required String newName,
    required AppUser user,
  });

  Future<void> deleteHomework({
    required int classroomId,
    required HomeworkFile homework,
    required AppUser user,
  });
}

class FirebaseHomeworkService implements HomeworkService {
  FirebaseHomeworkService({
    FirebaseDatabaseService? databaseService,
    StorageService? storageService,
  }) : _databaseService = databaseService ?? FirebaseDatabaseService(),
       _storageService = storageService ?? StorageService();

  static const allowedExtensions = {
    'pdf',
    'docx',
    'pptx',
    'jpg',
    'jpeg',
    'png',
    'gif',
    'webp',
    'bmp',
    'heic',
    'heif',
  };

  final FirebaseDatabaseService _databaseService;
  final StorageService _storageService;

  @override
  Stream<List<HomeworkFile>> watchHomework({
    required int classroomId,
    required AppUser user,
  }) {
    _requireClassroomAccess(user, classroomId);
    return _databaseService.watch(_homeworkFolder(classroomId)).map((value) {
      final items = _homeworkFromSnapshotValue(value);
      if (user.role == UserRole.student) {
        return items.where((item) => item.studentKey == user.key).toList();
      }
      return items;
    });
  }

  @override
  Future<HomeworkFile> uploadHomework({
    required int classroomId,
    required PickedNoteFile file,
    required AppUser uploadedBy,
  }) async {
    _requireStudent(uploadedBy);
    _requireClassroomAccess(uploadedBy, classroomId);
    _requireAllowedFile(file.name);
    if (file.bytes.isEmpty) {
      throw StateError('Selected file could not be read.');
    }

    final folder = _homeworkFolder(classroomId);
    final existing = await _databaseService.get(folder);
    final highestExistingId = _homeworkFromSnapshotValue(
      existing,
    ).fold<int>(1, (highest, item) => item.id > highest ? item.id : highest);
    final homeworkId = await _databaseService.reserveNextCounter(
      _databaseService.homeworkCounter(classroomId),
      minimumCurrentValue: highestExistingId,
    );
    final downloadUrl = await _storageService.uploadHomeworkFile(
      classroomId: classroomId,
      homeworkId: homeworkId,
      bytes: Uint8List.fromList(file.bytes),
      fileName: file.name,
      contentType: _contentTypeForFileName(file.name),
    );
    final homework = HomeworkFile(
      id: homeworkId,
      name: file.name,
      link: downloadUrl,
      createdAt: DateTime.now(),
      studentKey: uploadedBy.key,
      studentName: uploadedBy.fullName,
    );

    try {
      await _databaseService.set('$folder/$homeworkId', {
        'ID': homework.id,
        'Name': homework.name,
        'Link': homework.link,
        'Time': homework.createdAt.millisecondsSinceEpoch,
        'STUDENT_KEY': homework.studentKey,
        'STUDENT_NAME': homework.studentName,
      });
    } catch (_) {
      try {
        await _storageService.deleteHomeworkFile(classroomId, homeworkId);
      } catch (_) {
        // Preserve the database failure; classroom cleanup can remove the orphan.
      }
      rethrow;
    }
    return homework;
  }

  @override
  Future<void> renameHomework({
    required int classroomId,
    required HomeworkFile homework,
    required String newName,
    required AppUser user,
  }) async {
    await _requireOwner(
      user: user,
      classroomId: classroomId,
      homework: homework,
    );
    final trimmedName = newName.trim();
    if (trimmedName.isEmpty) {
      throw StateError('File name cannot be empty.');
    }
    _requireAllowedFile(trimmedName);
    await _databaseService.update(
      '${_homeworkFolder(classroomId)}/${homework.id}',
      {'Name': trimmedName},
    );
  }

  @override
  Future<void> deleteHomework({
    required int classroomId,
    required HomeworkFile homework,
    required AppUser user,
  }) async {
    await _requireOwner(
      user: user,
      classroomId: classroomId,
      homework: homework,
    );
    await _storageService.deleteHomeworkFile(classroomId, homework.id);
    await _databaseService.remove(
      '${_homeworkFolder(classroomId)}/${homework.id}',
    );
  }

  Future<void> _requireOwner({
    required AppUser user,
    required int classroomId,
    required HomeworkFile homework,
  }) async {
    _requireStudent(user);
    _requireClassroomAccess(user, classroomId);
    final value = await _databaseService.get(
      '${_homeworkFolder(classroomId)}/${homework.id}',
    );
    if (value is! Map || value['STUDENT_KEY'] != user.key) {
      throw StateError(
        'Only the student who uploaded this homework can change it.',
      );
    }
  }

  void _requireStudent(AppUser user) {
    if (user.role != UserRole.student) {
      throw StateError('Only students can upload or manage homework.');
    }
  }

  void _requireClassroomAccess(AppUser user, int classroomId) {
    if (!user.virtualRoomIds.contains(classroomId)) {
      throw StateError('You do not have access to this classroom.');
    }
  }

  void _requireAllowedFile(String fileName) {
    final extension = _extension(fileName);
    if (!allowedExtensions.contains(extension)) {
      throw StateError(
        'Homework must be a PDF, DOCX, PPTX, or supported image file.',
      );
    }
  }

  String _homeworkFolder(int classroomId) => '${classroomId}_HOMEWORK';

  String _extension(String fileName) {
    final parts = fileName.split('.');
    return parts.length > 1 ? parts.last.toLowerCase() : '';
  }

  String? _contentTypeForFileName(String fileName) {
    return switch (_extension(fileName)) {
      'pdf' => 'application/pdf',
      'docx' =>
        'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'pptx' =>
        'application/vnd.openxmlformats-officedocument.presentationml.presentation',
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'gif' => 'image/gif',
      'webp' => 'image/webp',
      'bmp' => 'image/bmp',
      'heic' => 'image/heic',
      'heif' => 'image/heif',
      _ => null,
    };
  }

  List<HomeworkFile> _homeworkFromSnapshotValue(Object? value) {
    final homework = <HomeworkFile>[];
    for (final item in _itemsFromSnapshotValue(value)) {
      homework.add(HomeworkFile.fromRealtimeDatabase(item));
    }
    homework.sort((left, right) => right.id.compareTo(left.id));
    return homework;
  }

  Iterable<Map<dynamic, dynamic>> _itemsFromSnapshotValue(Object? value) sync* {
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
