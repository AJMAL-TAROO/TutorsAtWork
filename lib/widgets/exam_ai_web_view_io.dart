import 'dart:io';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_windows/webview_windows.dart';

class ExamAiWebView extends StatefulWidget {
  const ExamAiWebView({required this.uri, super.key});

  final Uri uri;

  @override
  State<ExamAiWebView> createState() => _ExamAiWebViewState();
}

class _ExamAiWebViewState extends State<ExamAiWebView> {
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
        ..loadRequest(widget.uri);
    }
  }

  @override
  void dispose() {
    _windowsController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final errorMessage = _errorMessage;
    if (errorMessage != null) {
      return _ExamAiWebViewError(message: errorMessage);
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
      await controller.clearCache();
      await controller.loadUrl(_windowsUri(widget.uri).toString());

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
            'Could not start Exam AI. Make sure Microsoft Edge WebView2 Runtime is installed. Details: $error';
      });
    }
  }

  Uri _windowsUri(Uri uri) {
    return uri.replace(
      queryParameters: {
        ...uri.queryParameters,
        'webview_refresh': DateTime.now().millisecondsSinceEpoch.toString(),
      },
    );
  }
}

class _ExamAiWebViewError extends StatelessWidget {
  const _ExamAiWebViewError({required this.message});

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
                'Exam AI could not be loaded.',
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
