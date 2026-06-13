import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../models/app_user.dart';
import '../../models/homework_file.dart';
import '../../navigation/app_routes.dart';
import '../../providers/auth_provider.dart';
import '../../providers/homework_provider.dart';
import '../../services/homework_service.dart';
import '../../utils/note_downloader.dart';
import '../../utils/note_file_picker.dart';
import '../../widgets/app_shell.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/note_document_preview.dart';
import '../../widgets/note_pdf_preview.dart';

class HomeworkScreen extends ConsumerStatefulWidget {
  const HomeworkScreen({
    required this.classroomId,
    required this.classroomTitle,
    super.key,
  });

  final int classroomId;
  final String classroomTitle;

  @override
  ConsumerState<HomeworkScreen> createState() => _HomeworkScreenState();
}

class _HomeworkScreenState extends ConsumerState<HomeworkScreen> {
  bool _isUploading = false;

  HomeworkQuery _query(AppUser user) =>
      (classroomId: widget.classroomId, user: user);

  Future<void> _upload(AppUser user) async {
    setState(() => _isUploading = true);
    try {
      final file = await pickNoteFile(
        allowedExtensions: FirebaseHomeworkService.allowedExtensions.toList(),
      );
      if (file == null) {
        return;
      }
      await ref
          .read(homeworkServiceProvider)
          .uploadHomework(
            classroomId: widget.classroomId,
            file: file,
            uploadedBy: user,
          );
      ref.invalidate(homeworkProvider(_query(user)));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Homework uploaded successfully.')),
        );
      }
    } catch (error) {
      _showError('Upload failed', error);
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  Future<void> _rename(HomeworkFile homework, AppUser user) async {
    final controller = TextEditingController(text: homework.name);
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename homework'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'File name'),
          onSubmitted: (value) => Navigator.of(context).pop(value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (newName == null || newName.trim() == homework.name) {
      return;
    }
    try {
      await ref
          .read(homeworkServiceProvider)
          .renameHomework(
            classroomId: widget.classroomId,
            homework: homework,
            newName: newName,
            user: user,
          );
      ref.invalidate(homeworkProvider(_query(user)));
    } catch (error) {
      _showError('Rename failed', error);
    }
  }

  Future<void> _delete(HomeworkFile homework, AppUser user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete homework'),
        content: Text(
          'Delete "${homework.name}" from the classroom and Firebase Storage?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.of(context).pop(true),
            icon: const Icon(Icons.delete_outline),
            label: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }
    try {
      await ref
          .read(homeworkServiceProvider)
          .deleteHomework(
            classroomId: widget.classroomId,
            homework: homework,
            user: user,
          );
      ref.invalidate(homeworkProvider(_query(user)));
    } catch (error) {
      _showError('Delete failed', error);
    }
  }

  Future<void> _open(HomeworkFile homework) {
    return showDialog<void>(
      context: context,
      builder: (context) =>
          Dialog.fullscreen(child: _HomeworkPreview(homework: homework)),
    );
  }

  Future<void> _download(HomeworkFile homework) async {
    try {
      await downloadNote(homework);
    } catch (error) {
      _showError('Download failed', error);
    }
  }

  void _showError(String title, Object error) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$title: $error'),
        duration: const Duration(seconds: 8),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    if (user == null) {
      return const SizedBox.shrink();
    }
    final homework = ref.watch(homeworkProvider(_query(user)));
    final isStudent = user.role == UserRole.student;

    return AppShell(
      title: '${widget.classroomTitle} Homework',
      leading: IconButton(
        tooltip: 'Back to classrooms',
        onPressed: () => context.go(AppRoutes.classrooms),
        icon: const Icon(Icons.arrow_back),
      ),
      onBack: () async => context.go(AppRoutes.classrooms),
      floatingActionButton: isStudent
          ? FloatingActionButton.extended(
              onPressed: _isUploading ? null : () => _upload(user),
              icon: _isUploading
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.upload_file_outlined),
              label: Text(_isUploading ? 'Uploading' : 'Upload homework'),
            )
          : null,
      child: homework.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => EmptyState(
          icon: Icons.error_outline,
          title: 'Could not load homework',
          message: error.toString(),
        ),
        data: (items) {
          if (items.isEmpty) {
            return EmptyState(
              icon: Icons.assignment_outlined,
              title: 'No homework yet',
              message: isStudent
                  ? 'Your uploaded homework will appear here.'
                  : 'Student homework submissions will appear here.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(24),
            itemCount: items.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = items[index];
              return _HomeworkTile(
                homework: item,
                canManage: isStudent && item.studentKey == user.key,
                showStudent: !isStudent,
                onOpen: () => _open(item),
                onDownload: () => _download(item),
                onRename: () => _rename(item, user),
                onDelete: () => _delete(item, user),
              );
            },
          );
        },
      ),
    );
  }
}

class _HomeworkTile extends StatelessWidget {
  const _HomeworkTile({
    required this.homework,
    required this.canManage,
    required this.showStudent,
    required this.onOpen,
    required this.onDownload,
    required this.onRename,
    required this.onDelete,
  });

  final HomeworkFile homework;
  final bool canManage;
  final bool showStudent;
  final VoidCallback onOpen;
  final VoidCallback onDownload;
  final VoidCallback onRename;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('dd/MM/yyyy, HH:mm:ss').format(homework.createdAt);
    final subtitle = showStudent
        ? 'Submitted by ${homework.studentName}\nUploaded on: $date'
        : 'Uploaded on: $date';
    return Card(
      child: ListTile(
        leading: Icon(_iconForExtension(homework.extension), size: 32),
        title: Text(
          homework.name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(subtitle),
        isThreeLine: showStudent,
        onTap: onOpen,
        trailing: PopupMenuButton<_HomeworkAction>(
          tooltip: 'Homework actions',
          onSelected: (action) {
            switch (action) {
              case _HomeworkAction.open:
                onOpen();
              case _HomeworkAction.download:
                onDownload();
              case _HomeworkAction.rename:
                onRename();
              case _HomeworkAction.delete:
                onDelete();
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: _HomeworkAction.open,
              child: ListTile(
                leading: Icon(Icons.open_in_new),
                title: Text('Open'),
              ),
            ),
            const PopupMenuItem(
              value: _HomeworkAction.download,
              child: ListTile(
                leading: Icon(Icons.download_outlined),
                title: Text('Download'),
              ),
            ),
            if (canManage)
              const PopupMenuItem(
                value: _HomeworkAction.rename,
                child: ListTile(
                  leading: Icon(Icons.drive_file_rename_outline),
                  title: Text('Rename'),
                ),
              ),
            if (canManage)
              const PopupMenuItem(
                value: _HomeworkAction.delete,
                child: ListTile(
                  leading: Icon(Icons.delete_outline),
                  title: Text('Delete'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  IconData _iconForExtension(String extension) {
    return switch (extension) {
      'jpg' ||
      'jpeg' ||
      'png' ||
      'gif' ||
      'webp' ||
      'bmp' ||
      'heic' ||
      'heif' => Icons.image_outlined,
      'pdf' => Icons.picture_as_pdf_outlined,
      'docx' => Icons.description_outlined,
      'pptx' => Icons.slideshow_outlined,
      _ => Icons.insert_drive_file_outlined,
    };
  }
}

enum _HomeworkAction { open, download, rename, delete }

class _HomeworkPreview extends StatelessWidget {
  const _HomeworkPreview({required this.homework});

  final HomeworkFile homework;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(homework.name)),
      body: switch ((
        homework.isImage,
        homework.isPdf,
        homework.isOfficeDocument,
      )) {
        (true, _, _) => Center(
          child: InteractiveViewer(
            minScale: 0.5,
            maxScale: 5,
            child: Image.network(homework.link),
          ),
        ),
        (_, true, _) => NotePdfPreview(url: homework.link),
        (_, _, true) => NoteDocumentPreview(url: homework.link),
        _ => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Preview is not available for this image format. Download the file to open it.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      },
    );
  }
}
