import 'firebase_database_service.dart';
import 'storage_service.dart';
import '../models/app_user.dart';
import '../models/classroom.dart';

abstract class ClassroomService {
  Future<List<Classroom>> classroomsForRoomIds(List<int> roomIds);

  Stream<List<Classroom>> watchClassroomsForUser(AppUser user);

  Future<Classroom> createClassroom({
    required String adminKey,
    required ClassroomDraft draft,
  });

  Future<void> deleteClassroom({
    required String adminKey,
    required Classroom classroom,
  });

  Future<String?> virtualRoomLinkForClassroom({
    required AppUser user,
    required Classroom classroom,
  });
}

class RealtimeDatabaseClassroomService implements ClassroomService {
  RealtimeDatabaseClassroomService({
    FirebaseDatabaseService? databaseService,
    StorageService? storageService,
  }) : _databaseService = databaseService ?? FirebaseDatabaseService(),
       _storageService = storageService ?? StorageService();

  final FirebaseDatabaseService _databaseService;
  final StorageService _storageService;

  @override
  Future<List<Classroom>> classroomsForRoomIds(List<int> roomIds) async {
    if (roomIds.isEmpty) {
      return const [];
    }

    final classrooms = await _databaseService.get(_databaseService.classrooms);

    if (classrooms is! Map) {
      return const [];
    }

    final allowedRoomIds = roomIds.toSet();
    final results = <Classroom>[];

    for (final value in classrooms.values) {
      if (value is! Map) {
        continue;
      }

      final classroom = Classroom.fromRealtimeDatabase(value);
      if (allowedRoomIds.contains(classroom.id)) {
        results.add(classroom);
      }
    }

    results.sort((left, right) => left.id.compareTo(right.id));
    return results;
  }

  @override
  Stream<List<Classroom>> watchClassroomsForUser(AppUser user) {
    return _databaseService.watch(_userPath(user)).asyncMap((value) {
      final data = value is Map ? value : const {};
      final roomIds = _intIds(data['VIRTUAL_ROOMS']);
      return classroomsForRoomIds(roomIds);
    });
  }

  @override
  Future<Classroom> createClassroom({
    required String adminKey,
    required ClassroomDraft draft,
  }) async {
    final counterPath = 'NUMBERS/CURRENT_ID_CLASSROOM/NUMBER';
    final currentCounter = await _databaseService.get(counterPath);
    final currentId = int.tryParse(currentCounter?.toString() ?? '') ?? 0;
    final classroomId = currentId + 1;
    final storageFolder = '${classroomId}_NOTES';
    final adminValue = await _databaseService.get('ADMIN/$adminKey');
    final adminData = adminValue is Map ? adminValue : const {};
    final teacherName = adminData['FULL_NAME']?.toString() ?? '';
    final teacherPhone = adminData['TEL']?.toString() ?? '';
    final virtualRoomLink = adminData['VR_LINK']?.toString();

    await _databaseService.set(
      '${_databaseService.classrooms}/CLASSROOM_$classroomId',
      draft.toRealtimeDatabase(
        classroomId: classroomId,
        storageFolder: storageFolder,
        teacherName: teacherName,
        teacherPhone: teacherPhone,
        virtualRoomLink: virtualRoomLink,
      ),
    );
    await _databaseService.set(counterPath, classroomId);
    await _databaseService.set(
      'NUMBERS/ID_CLASSROOM_${classroomId}_NOTES/NUMBER',
      1,
    );
    await _databaseService.set(
      'NUMBERS/ID_CLASSROOM_${classroomId}_HOMEWORK/NUMBER',
      1,
    );
    await _addClassroomToAdmin(adminKey: adminKey, classroomId: classroomId);
    await _databaseService.set('ADMIN/$adminKey/LOGS/LAST_CREATED_CLASSROOM', {
      'CLASSROOM_ID': classroomId,
      'CLASSROOM_TITLE': draft.title,
      'TIMESTAMP': DateTime.now().millisecondsSinceEpoch,
      'DATE': DateTime.now().toIso8601String(),
    });

    return Classroom(
      id: classroomId,
      title: draft.title,
      storageFolder: storageFolder,
      teacherName: teacherName,
      teacherAddress: '',
      teacherPhone: teacherPhone,
      virtualRoomLink: virtualRoomLink,
    );
  }

  @override
  Future<void> deleteClassroom({
    required String adminKey,
    required Classroom classroom,
  }) async {
    await _deleteHomeworkFiles(classroom.id);
    await _removeClassroomFromAdmin(
      adminKey: adminKey,
      classroomId: classroom.id,
    );
    await _removeClassroomFromStudents(classroom.id);
    await _databaseService.remove(
      '${_databaseService.classrooms}/CLASSROOM_${classroom.id}',
    );
    await _databaseService.remove(classroom.storageFolder);
    await _databaseService.remove('${classroom.id}_HOMEWORK');
    await _databaseService.remove('NUMBERS/ID_CLASSROOM_${classroom.id}_NOTES');
    await _databaseService.remove(
      'NUMBERS/ID_CLASSROOM_${classroom.id}_HOMEWORK',
    );
    await _databaseService.set('ADMIN/$adminKey/LOGS/LAST_DELETED_CLASSROOM', {
      'CLASSROOM_ID': classroom.id,
      'CLASSROOM_TITLE': classroom.title,
      'TIMESTAMP': DateTime.now().millisecondsSinceEpoch,
      'DATE': DateTime.now().toIso8601String(),
    });
  }

  Future<void> _deleteHomeworkFiles(int classroomId) async {
    final value = await _databaseService.get('${classroomId}_HOMEWORK');
    final records = value is Map
        ? value.values
        : value is List
        ? value
        : const <Object?>[];
    for (final record in records) {
      if (record is! Map) {
        continue;
      }
      final id = int.tryParse(record['ID']?.toString() ?? '');
      if (id != null) {
        await _storageService.deleteHomeworkFile(classroomId, id);
      }
    }
  }

  @override
  Future<String?> virtualRoomLinkForClassroom({
    required AppUser user,
    required Classroom classroom,
  }) async {
    final classroomLink = _nonEmptyString(classroom.virtualRoomLink);
    if (classroomLink != null) {
      return classroomLink;
    }

    if (user.role == UserRole.admin) {
      final value = await _databaseService.get('ADMIN/${user.key}');
      final data = value is Map ? value : const {};
      return _nonEmptyString(data['VR_LINK']);
    }

    final admins = await _databaseService.get(_databaseService.admins);
    if (admins is! Map) {
      return null;
    }

    for (final value in admins.values) {
      if (value is! Map) {
        continue;
      }
      if (!_intIds(value['VIRTUAL_ROOMS']).contains(classroom.id)) {
        continue;
      }
      final link = _nonEmptyString(value['VR_LINK']);
      if (link != null) {
        return link;
      }
    }

    return null;
  }

  Future<void> _addClassroomToAdmin({
    required String adminKey,
    required int classroomId,
  }) async {
    final current = await _databaseService.get('ADMIN/$adminKey/VIRTUAL_ROOMS');
    final ids = _intIds(current)..add(classroomId);
    final sorted = ids.toSet().toList()..sort();
    await _databaseService.set(
      'ADMIN/$adminKey/VIRTUAL_ROOMS',
      sorted.join(','),
    );
  }

  Future<void> _removeClassroomFromAdmin({
    required String adminKey,
    required int classroomId,
  }) async {
    final current = await _databaseService.get('ADMIN/$adminKey/VIRTUAL_ROOMS');
    final ids = _intIds(current).where((id) => id != classroomId).toList()
      ..sort();
    await _databaseService.set('ADMIN/$adminKey/VIRTUAL_ROOMS', ids.join(','));
  }

  Future<void> _removeClassroomFromStudents(int classroomId) async {
    final value = await _databaseService.get(_databaseService.students);
    if (value is! Map) {
      return;
    }

    for (final entry in value.entries) {
      final data = entry.value;
      if (data is! Map) {
        continue;
      }
      final roomIds = _intIds(data['VIRTUAL_ROOMS']);
      if (!roomIds.contains(classroomId)) {
        continue;
      }
      final updatedRoomIds = roomIds.where((id) => id != classroomId).toList()
        ..sort();
      await _databaseService.update(
        '${_databaseService.students}/${entry.key}',
        {'VIRTUAL_ROOMS': updatedRoomIds.join(',')},
      );
    }
  }

  List<int> _intIds(Object? value) {
    return (value?.toString() ?? '')
        .split(',')
        .map((id) => int.tryParse(id.trim()))
        .whereType<int>()
        .toList();
  }

  String? _nonEmptyString(Object? value) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }

  String _userPath(AppUser user) {
    return user.role == UserRole.admin
        ? '${_databaseService.admins}/${user.key}'
        : '${_databaseService.students}/${user.key}';
  }
}
