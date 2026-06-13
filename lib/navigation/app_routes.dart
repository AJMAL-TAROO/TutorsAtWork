class AppRoutes {
  const AppRoutes._();

  static const login = '/';
  static const dashboard = '/dashboard';
  static const classrooms = '/classrooms';
  static const students = '/students';
  static const timetable = '/timetable';
  static const attendance = '/attendance';
  static const feedback = '/feedback';
  static const whiteboard = '/whiteboard';
  static const examAi = '/exam-ai';
  static const classroomNotes = '/classrooms/:classroomId/notes';
  static const classroomHomework = '/classrooms/:classroomId/homework';
  static const classroomComments = '/classrooms/:classroomId/comments';

  static String notesForClassroom(int classroomId) {
    return '/classrooms/$classroomId/notes';
  }

  static String commentsForClassroom(int classroomId) {
    return '/classrooms/$classroomId/comments';
  }

  static String homeworkForClassroom(int classroomId) {
    return '/classrooms/$classroomId/homework';
  }
}
