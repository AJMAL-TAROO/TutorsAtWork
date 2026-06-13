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

  String get extension {
    final parts = name.split('.');
    return parts.length > 1 ? parts.last.toLowerCase() : '';
  }

  bool get isImage {
    return const {
      'jpg',
      'jpeg',
      'png',
      'gif',
      'webp',
      'bmp',
    }.contains(extension);
  }

  bool get isPdf {
    return extension == 'pdf';
  }

  bool get isOfficeDocument {
    return const {'doc', 'docx', 'ppt', 'pptx'}.contains(extension);
  }
}
