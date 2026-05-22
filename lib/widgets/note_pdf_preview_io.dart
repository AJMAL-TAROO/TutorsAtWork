import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class NotePdfPreview extends StatelessWidget {
  const NotePdfPreview({required this.url, super.key});

  final String url;

  @override
  Widget build(BuildContext context) {
    return SfPdfViewer.network(url);
  }
}
