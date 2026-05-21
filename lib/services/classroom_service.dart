import '../models/classroom.dart';

abstract class ClassroomService {
  Future<List<Classroom>> classroomsForRoomIds(List<int> roomIds);
}

class PlaceholderClassroomService implements ClassroomService {
  const PlaceholderClassroomService();

  @override
  Future<List<Classroom>> classroomsForRoomIds(List<int> roomIds) async {
    final classrooms = _previewClassrooms
        .where((classroom) => roomIds.contains(classroom.id))
        .toList();

    return classrooms.isEmpty ? _previewClassrooms : classrooms;
  }
}

const _previewClassrooms = [
  Classroom(
    id: 1001,
    title: 'English',
    storageFolder: '1001_NOTES',
    teacherName: 'Mohamade Ajmal Taroo',
    teacherPhone: '59185657',
    virtualRoomLink: 'https://mindtech.daily.co/ENGLISH_VR_LINK',
  ),
  Classroom(
    id: 1002,
    title: 'Mathematics',
    storageFolder: '1002_NOTES',
    teacherName: 'Ajmal Taroo',
    teacherPhone: '58505488',
  ),
  Classroom(
    id: 1003,
    title: 'Computer Science',
    storageFolder: '1003_NOTES',
    teacherName: 'Mohamade Ajmal Taroo',
    teacherPhone: '58505488',
  ),
];
