class AppRoutes {
  const AppRoutes._();

  static const login = '/';
  static const dashboard = '/dashboard';
  static const classrooms = '/classrooms';
  static const timetable = '/timetable';
  static const attendance = '/attendance';
  static const classroomNotes = '/classrooms/:classroomId/notes';

  static String notesForClassroom(int classroomId) {
    return '/classrooms/$classroomId/notes';
  }
}
