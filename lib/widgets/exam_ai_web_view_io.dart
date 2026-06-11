import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_windows/webview_windows.dart';

class ExamAiWebView extends StatefulWidget {
  const ExamAiWebView({
    required this.uri,
    required this.onNativeMessage,
    super.key,
  });

  final Uri uri;
  final Future<Map<String, Object?>> Function(Map<String, Object?> message)
  onNativeMessage;

  @override
  State<ExamAiWebView> createState() => _ExamAiWebViewState();
}

class _ExamAiWebViewState extends State<ExamAiWebView> {
  WebViewController? _mobileController;
  WebviewController? _windowsController;
  StreamSubscription<dynamic>? _windowsMessageSubscription;
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
        ..addJavaScriptChannel(
          'TawNativeBridge',
          onMessageReceived: (message) => _handleMobileMessage(message.message),
        )
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
    _windowsMessageSubscription?.cancel();
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
      _windowsMessageSubscription = controller.webMessage.listen(
        (message) => _handleWindowsMessage(controller, message),
      );
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

  Future<void> _handleMobileMessage(String rawMessage) async {
    final controller = _mobileController;
    if (controller == null) {
      return;
    }
    final response = await _handleMessage(rawMessage);
    await controller.runJavaScript(
      'window.tawNativeResult(${jsonEncode(response)});',
    );
  }

  Future<void> _handleWindowsMessage(
    WebviewController controller,
    dynamic rawMessage,
  ) async {
    final response = await _handleMessage(rawMessage);
    await controller.executeScript(
      'window.tawNativeResult(${jsonEncode(response)});',
    );
  }

  Future<Map<String, Object?>> _handleMessage(dynamic rawMessage) async {
    Map<String, Object?> message;
    try {
      final decoded = rawMessage is String
          ? jsonDecode(rawMessage)
          : rawMessage;
      if (decoded is! Map) {
        throw const FormatException('Native message must be an object.');
      }
      message = decoded.map((key, value) => MapEntry(key.toString(), value));
    } catch (error) {
      return {
        'requestId': '',
        'ok': false,
        'message': 'Could not read Exam AI request: $error',
      };
    }

    try {
      return await widget.onNativeMessage(message);
    } catch (error) {
      return {
        'requestId': message['requestId']?.toString() ?? '',
        'ok': false,
        'message': error.toString().replaceFirst('Bad state: ', ''),
      };
    }
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
