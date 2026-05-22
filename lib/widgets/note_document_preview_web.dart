// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';

class NoteDocumentPreview extends StatelessWidget {
  NoteDocumentPreview({required this.url, super.key})
    : _viewType = 'note-document-${url.hashCode}';

  final String url;
  final String _viewType;

  @override
  Widget build(BuildContext context) {
    ui_web.platformViewRegistry.registerViewFactory(_viewType, (viewId) {
      return html.IFrameElement()
        ..src = _viewerUri(url).toString()
        ..style.border = '0'
        ..style.width = '100%'
        ..style.height = '100%'
        ..allowFullscreen = true;
    });

    return HtmlElementView(viewType: _viewType);
  }

  Uri _viewerUri(String fileUrl) {
    return Uri.https('docs.google.com', '/gview', {
      'embedded': '1',
      'url': fileUrl,
    });
  }
}
