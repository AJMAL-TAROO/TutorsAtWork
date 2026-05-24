import 'dart:io';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_windows/webview_windows.dart';

class NoteDocumentPreview extends StatefulWidget {
  const NoteDocumentPreview({required this.url, super.key});

  final String url;

  @override
  State<NoteDocumentPreview> createState() => _NoteDocumentPreviewState();
}

class _NoteDocumentPreviewState extends State<NoteDocumentPreview> {
  WebViewController? _mobileController;
  WebviewController? _windowsController;
  var _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    if (Platform.isWindows) {
      _initializeWindowsWebView();
    } else {
      _mobileController = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageFinished: (_) {
              if (mounted) {
                setState(() => _isLoading = false);
              }
            },
            onWebResourceError: (error) {
              if (mounted && error.isForMainFrame == true) {
                setState(() {
                  _isLoading = false;
                  _errorMessage = error.description;
                });
              }
            },
          ),
        )
        ..loadRequest(_viewerUri(widget.url));
    }
  }

  @override
  void dispose() {
    _windowsController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_errorMessage != null) {
      return _DocumentPreviewError(message: _errorMessage!);
    }

    final windowsController = _windowsController;
    final mobileController = _mobileController;

    return Stack(
      children: [
        if (Platform.isWindows && windowsController != null)
          Webview(windowsController)
        else if (mobileController != null)
          WebViewWidget(controller: mobileController),
        if (_isLoading) const Center(child: CircularProgressIndicator()),
      ],
    );
  }

  Future<void> _initializeWindowsWebView() async {
    final controller = WebviewController();
    try {
      await controller.initialize();
      await controller.setBackgroundColor(Colors.white);
      await controller.setPopupWindowPolicy(WebviewPopupWindowPolicy.deny);
      await controller.loadUrl(_viewerUri(widget.url).toString());

      if (!mounted) {
        controller.dispose();
        return;
      }

      setState(() {
        _windowsController = controller;
        _isLoading = false;
      });
    } catch (error) {
      controller.dispose();
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
        _errorMessage =
            'Could not start the Windows document viewer. Make sure Microsoft Edge WebView2 Runtime is installed. Details: $error';
      });
    }
  }

  Uri _viewerUri(String fileUrl) {
    return Uri.https('docs.google.com', '/gview', {
      'embedded': '1',
      'url': fileUrl,
    });
  }
}

class _DocumentPreviewError extends StatelessWidget {
  const _DocumentPreviewError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.description_outlined,
                size: 56,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'Document preview could not be loaded.',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(message, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
