class ClassroomComment {
  const ClassroomComment({
    required this.id,
    required this.email,
    required this.date,
    required this.comment,
    required this.authorKey,
    required this.authorRole,
  });

  factory ClassroomComment.fromRealtimeDatabase({
    required String id,
    required Map<dynamic, dynamic> data,
  }) {
    return ClassroomComment(
      id: id,
      email: data['EMAIL']?.toString() ?? 'Unknown',
      date: data['DATE']?.toString() ?? '',
      comment: data['COMMENT']?.toString() ?? '',
      authorKey: data['AUTHOR_KEY']?.toString() ?? '',
      authorRole: data['AUTHOR_ROLE']?.toString() ?? '',
    );
  }

  final String id;
  final String email;
  final String date;
  final String comment;
  final String authorKey;
  final String authorRole;
}
