class Classroom {
  const Classroom({
    required this.id,
    required this.title,
    required this.storageFolder,
    required this.teacherName,
    required this.teacherPhone,
    this.virtualRoomLink,
  });

  factory Classroom.fromRealtimeDatabase(Map<dynamic, dynamic> data) {
    return Classroom(
      id: data['CLASSROOM_ID'] as int? ?? 0,
      title: data['TITLE'] as String? ?? 'Untitled classroom',
      storageFolder: data['STORAGE_FOLDER'] as String? ?? '',
      teacherName: data['TEACHER_FULL_NAME'] as String? ?? '',
      teacherPhone: data['TEACHER_TEL']?.toString() ?? '',
      virtualRoomLink: data['VR_LINK'] as String?,
    );
  }

  final int id;
  final String title;
  final String storageFolder;
  final String teacherName;
  final String teacherPhone;
  final String? virtualRoomLink;
}
