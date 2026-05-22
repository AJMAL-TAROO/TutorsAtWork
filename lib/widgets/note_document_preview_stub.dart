import 'package:flutter/material.dart';

class NoteDocumentPreview extends StatelessWidget {
  const NoteDocumentPreview({required this.url, super.key});

  final String url;

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Document preview is not supported here.'));
  }
}
