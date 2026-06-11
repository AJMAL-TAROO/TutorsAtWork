import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/app_user.dart';
import '../../navigation/app_routes.dart';
import '../../providers/auth_provider.dart';
import '../../providers/classrooms_provider.dart';
import '../../providers/exam_ai_provider.dart';
import '../../providers/notes_provider.dart';
import '../../utils/generated_pdf_saver.dart';
import '../../utils/note_file_picker.dart';
import '../../widgets/app_shell.dart';
import '../../widgets/exam_ai_web_view.dart';

class ExamAiScreen extends ConsumerStatefulWidget {
  const ExamAiScreen({this.initialUrl, super.key});

  final String? initialUrl;

  @override
  ConsumerState<ExamAiScreen> createState() => _ExamAiScreenState();
}

class _ExamAiScreenState extends ConsumerState<ExamAiScreen> {
  Future<Uri>? _sessionUriFuture;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);

    return AppShell(
      title: 'Exam AI',
      leading: IconButton(
        tooltip: 'Back to dashboard',
        onPressed: () => context.go(AppRoutes.dashboard),
        icon: const Icon(Icons.arrow_back),
      ),
      onBack: () async => context.go(AppRoutes.dashboard),
      child: _buildBody(context, user),
    );
  }

  Widget _buildBody(BuildContext context, AppUser? user) {
    if (user == null) {
      return const Center(child: Text('Sign in again to use Exam AI.'));
    }
    if (user.role != UserRole.admin) {
      return const Center(child: Text('Exam AI is available to tutors only.'));
    }

    _sessionUriFuture ??= _createSessionUri(user);

    return FutureBuilder<Uri>(
      future: _sessionUriFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return _ExamAiError(message: snapshot.error.toString());
        }
        return ExamAiWebView(
          uri: snapshot.data!,
          onNativeMessage: (message) => _handleNativeMessage(user, message),
        );
      },
    );
  }

  Future<Uri> _createSessionUri(AppUser user) {
    final url = widget.initialUrl;
    if (url != null && url.trim().isNotEmpty) {
      return Future<Uri>.sync(() => Uri.parse(url));
    }
    return ref.read(examAiServiceProvider).createSessionUri(user);
  }

  Future<Map<String, Object?>> _handleNativeMessage(
    AppUser user,
    Map<String, Object?> message,
  ) async {
    final requestId = message['requestId']?.toString() ?? '';
    final action = message['action']?.toString() ?? '';
    final fileName = _pdfFileName(message['fileName']?.toString() ?? '');
    final encodedPdf = message['pdfBase64']?.toString() ?? '';

    if (requestId.isEmpty || encodedPdf.isEmpty) {
      throw StateError('Exam AI sent an incomplete PDF request.');
    }

    final bytes = base64Decode(encodedPdf);
    if (bytes.isEmpty) {
      throw StateError('Exam AI generated an empty PDF.');
    }
    if (bytes.length > 40 * 1024 * 1024) {
      throw StateError('The generated PDF is too large. Use fewer questions.');
    }

    if (action == 'downloadPdf') {
      await saveGeneratedPdf(fileName: fileName, bytes: bytes);
      return {
        'requestId': requestId,
        'ok': true,
        'fileName': fileName,
        'message': 'PDF saved and opened.',
      };
    }

    if (action == 'uploadPdf') {
      final classroomId = int.tryParse(
        message['classroomId']?.toString() ?? '',
      );
      if (classroomId == null) {
        throw StateError('Select a classroom before uploading.');
      }

      final classrooms = await ref
          .read(classroomServiceProvider)
          .classroomsForRoomIds(user.virtualRoomIds);
      final classroom = classrooms
          .where((item) => item.id == classroomId)
          .firstOrNull;
      if (classroom == null) {
        throw StateError(
          'This classroom does not belong to the signed-in tutor.',
        );
      }

      await ref
          .read(noteServiceProvider)
          .uploadNote(
            classroomId: classroom.id,
            storageFolder: classroom.storageFolder,
            file: PickedNoteFile(
              name: fileName,
              size: bytes.length,
              bytes: bytes,
            ),
            uploadedBy: user,
          );
      ref.invalidate(notesProvider(classroom.storageFolder));

      return {
        'requestId': requestId,
        'ok': true,
        'fileName': fileName,
        'message': 'Uploaded to ${classroom.title} notes.',
      };
    }

    throw StateError('Unsupported Exam AI action.');
  }

  String _pdfFileName(String value) {
    final cleaned = value
        .replaceAll(RegExp(r'[\\/:*?"<>|]+'), '-')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    final name = cleaned.isEmpty ? 'Generated Exam Paper' : cleaned;
    return name.toLowerCase().endsWith('.pdf') ? name : '$name.pdf';
  }
}

class _ExamAiError extends StatelessWidget {
  const _ExamAiError({required this.message});

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
                'Could not open Exam AI.',
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
