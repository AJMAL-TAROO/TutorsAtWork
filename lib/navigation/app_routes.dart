class AppRoutes {
  const AppRoutes._();

  static const login = '/';
  static const dashboard = '/dashboard';
  static const classrooms = '/classrooms';
  static const classroomNotes = '/classrooms/:classroomId/notes';

  static String notesForClassroom(int classroomId) {
    return '/classrooms/$classroomId/notes';
  }
}
