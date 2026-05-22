import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class NoteDocumentPreview extends StatefulWidget {
  const NoteDocumentPreview({required this.url, super.key});

  final String url;

  @override
  State<NoteDocumentPreview> createState() => _NoteDocumentPreviewState();
}

class _NoteDocumentPreviewState extends State<NoteDocumentPreview> {
  late final WebViewController _controller;
  var _isLoading = true;

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            if (mounted) {
              setState(() => _isLoading = false);
            }
          },
        ),
      )
      ..loadRequest(_viewerUri(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        WebViewWidget(controller: _controller),
        if (_isLoading) const Center(child: CircularProgressIndicator()),
      ],
    );
  }

  Uri _viewerUri(String fileUrl) {
    return Uri.https('docs.google.com', '/gview', {
      'embedded': '1',
      'url': fileUrl,
    });
  }
}
