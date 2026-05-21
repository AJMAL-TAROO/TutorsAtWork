class NoteFile {
  const NoteFile({
    required this.id,
    required this.name,
    required this.link,
    required this.createdAt,
  });

  factory NoteFile.fromRealtimeDatabase(Map<dynamic, dynamic> data) {
    return NoteFile(
      id: data['ID'] as int? ?? 0,
      name: data['Name'] as String? ?? 'Untitled file',
      link: data['Link'] as String? ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(data['Time'] as int? ?? 0),
    );
  }

  final int id;
  final String name;
  final String link;
  final DateTime createdAt;
}
