class AppUpdate {
  const AppUpdate({
    required this.version,
    required this.description,
    required this.link,
  });

  factory AppUpdate.fromRealtimeDatabase(Map<dynamic, dynamic> data) {
    return AppUpdate(
      version: data['VALUE']?.toString().trim() ?? '',
      description: data['DESCRIPTION']?.toString().trim() ?? '',
      link: Uri.tryParse(data['LINK']?.toString().trim() ?? ''),
    );
  }

  final String version;
  final String description;
  final Uri? link;
}
