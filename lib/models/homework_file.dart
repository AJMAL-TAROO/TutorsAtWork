import 'note_file.dart';

class HomeworkFile extends NoteFile {
  const HomeworkFile({
    required super.id,
    required super.name,
    required super.link,
    required super.createdAt,
    required this.studentKey,
    required this.studentName,
  });

  factory HomeworkFile.fromRealtimeDatabase(Map<dynamic, dynamic> data) {
    return HomeworkFile(
      id: (data['ID'] as num?)?.toInt() ?? 0,
      name: data['Name'] as String? ?? 'Untitled homework',
      link: data['Link'] as String? ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        (data['Time'] as num?)?.toInt() ?? 0,
      ),
      studentKey: data['STUDENT_KEY'] as String? ?? '',
      studentName: data['STUDENT_NAME'] as String? ?? 'Unknown student',
    );
  }

  final String studentKey;
  final String studentName;
}
