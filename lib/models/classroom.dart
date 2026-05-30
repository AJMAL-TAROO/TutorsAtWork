class Classroom {
  const Classroom({
    required this.id,
    required this.title,
    required this.storageFolder,
    required this.teacherName,
    required this.teacherAddress,
    required this.teacherPhone,
    this.virtualRoomLink,
  });

  factory Classroom.fromRealtimeDatabase(Map<dynamic, dynamic> data) {
    return Classroom(
      id: data['CLASSROOM_ID'] as int? ?? 0,
      title: data['TITLE'] as String? ?? 'Untitled classroom',
      storageFolder: data['STORAGE_FOLDER'] as String? ?? '',
      teacherName: data['TEACHER_FULL_NAME'] as String? ?? '',
      teacherAddress: data['TEACHER_ADDRESS']?.toString() ?? '',
      teacherPhone: data['TEACHER_TEL']?.toString() ?? '',
      virtualRoomLink: data['VR_LINK'] as String?,
    );
  }

  final int id;
  final String title;
  final String storageFolder;
  final String teacherName;
  final String teacherAddress;
  final String teacherPhone;
  final String? virtualRoomLink;
}

class ClassroomDraft {
  const ClassroomDraft({required this.title});

  final String title;

  Map<String, Object?> toRealtimeDatabase({
    required int classroomId,
    required String storageFolder,
    required String teacherName,
    required String teacherPhone,
    String teacherAddress = '',
    String? virtualRoomLink,
  }) {
    return {
      'CLASSROOM_ID': classroomId,
      'STORAGE_FOLDER': storageFolder,
      'TEACHER_ADDRESS': teacherAddress,
      'TEACHER_FULL_NAME': teacherName,
      'TEACHER_TEL': teacherPhone,
      'TITLE': title,
      'VR_LINK': virtualRoomLink,
    };
  }
}
