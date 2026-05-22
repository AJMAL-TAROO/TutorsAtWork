import 'package:flutter/material.dart';

class NotePdfPreview extends StatelessWidget {
  const NotePdfPreview({required this.url, super.key});

  final String url;

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('PDF preview is not supported here.'));
  }
}
