class StudentFeedback {
  const StudentFeedback({
    required this.id,
    required this.studentKey,
    required this.studentName,
    required this.tutorKey,
    required this.tutorName,
    required this.tutorEmail,
    required this.date,
    required this.updatedDate,
    required this.message,
    required this.timestamp,
  });

  factory StudentFeedback.fromRealtimeDatabase({
    required String id,
    required Map<dynamic, dynamic> data,
  }) {
    return StudentFeedback(
      id: id,
      studentKey: data['STUDENT_KEY']?.toString() ?? '',
      studentName: data['STUDENT_NAME']?.toString() ?? 'Unknown student',
      tutorKey: data['TUTOR_KEY']?.toString() ?? '',
      tutorName: data['TUTOR_NAME']?.toString() ?? 'Tutor',
      tutorEmail: data['TUTOR_EMAIL']?.toString() ?? '',
      date: data['DATE']?.toString() ?? '',
      updatedDate: data['UPDATED_DATE']?.toString() ?? '',
      message: data['MESSAGE']?.toString() ?? '',
      timestamp: int.tryParse(data['TIMESTAMP']?.toString() ?? '') ?? 0,
    );
  }

  final String id;
  final String studentKey;
  final String studentName;
  final String tutorKey;
  final String tutorName;
  final String tutorEmail;
  final String date;
  final String updatedDate;
  final String message;
  final int timestamp;

  bool get wasUpdated => updatedDate.isNotEmpty && updatedDate != date;
}
