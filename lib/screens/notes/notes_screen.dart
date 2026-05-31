import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../models/app_user.dart';
import '../../models/note_file.dart';
import '../../navigation/app_routes.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notes_provider.dart';
import '../../utils/note_downloader.dart';
import '../../utils/note_file_picker.dart';
import '../../widgets/app_shell.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/note_document_preview.dart';
import '../../widgets/note_pdf_preview.dart';

class NotesScreen extends ConsumerStatefulWidget {
  const NotesScreen({
    required this.classroomId,
    required this.classroomTitle,
    required this.storageFolder,
    super.key,
  });

  final int classroomId;
  final String classroomTitle;
  final String storageFolder;

  @override
  ConsumerState<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends ConsumerState<NotesScreen> {
  bool _isUploading = false;

  Future<void> _showUploadDialog(AppUser user) async {
    final uploaded = await showDialog<bool>(
      context: context,
      barrierDismissible: !_isUploading,
      builder: (dialogContext) {
        PickedNoteFile? selectedFile;
        var isSelecting = false;
        var isUploading = false;
        String? errorMessage;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> selectFile() async {
              setDialogState(() {
                isSelecting = true;
                errorMessage = null;
              });

              try {
                final result = await pickNoteFile();
                setDialogState(() => selectedFile = result);
              } catch (error) {
                setDialogState(() => errorMessage = '$error');
              } finally {
                setDialogState(() => isSelecting = false);
              }
            }

            Future<void> uploadSelectedFile() async {
              final file = selectedFile;
              if (file == null) {
                setDialogState(() {
                  errorMessage = 'Select a file before uploading.';
                });
                return;
              }

              setState(() => _isUploading = true);
              setDialogState(() {
                isUploading = true;
                errorMessage = null;
              });

              try {
                await ref
                    .read(noteServiceProvider)
                    .uploadNote(
                      classroomId: widget.classroomId,
                      storageFolder: widget.storageFolder,
                      file: file,
                      uploadedBy: user,
                    );
                ref.invalidate(notesProvider(widget.storageFolder));

                if (context.mounted) {
                  Navigator.of(dialogContext).pop(true);
                }
              } catch (error) {
                setDialogState(() => errorMessage = '$error');
              } finally {
                if (mounted) {
                  setState(() => _isUploading = false);
                }
                if (context.mounted) {
                  setDialogState(() => isUploading = false);
                }
              }
            }

            return AlertDialog(
              title: const Text('Upload note'),
              content: SizedBox(
                width: 420,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    OutlinedButton.icon(
                      onPressed: isSelecting || isUploading ? null : selectFile,
                      icon: isSelecting
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.attach_file),
                      label: Text(
                        selectedFile == null ? 'Select file' : 'Change file',
                      ),
                    ),
                    if (selectedFile != null) ...[
                      const SizedBox(height: 16),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.insert_drive_file_outlined),
                        title: Text(
                          selectedFile!.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(_formatFileSize(selectedFile!.size)),
                      ),
                    ],
                    if (errorMessage != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        errorMessage!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isUploading
                      ? null
                      : () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Cancel'),
                ),
                FilledButton.icon(
                  onPressed: isUploading ? null : uploadSelectedFile,
                  icon: isUploading
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.cloud_upload_outlined),
                  label: Text(isUploading ? 'Uploading' : 'Upload'),
                ),
              ],
            );
          },
        );
      },
    );

    if (uploaded == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Note uploaded successfully.')),
      );
    }
  }

  Future<void> _renameNote(NoteFile note) async {
    final controller = TextEditingController(text: note.name);
    final newName = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Rename note'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'File name'),
            textInputAction: TextInputAction.done,
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
        );
      },
    );
    controller.dispose();

    if (newName == null || newName.trim() == note.name) {
      return;
    }

    try {
      await ref
          .read(noteServiceProvider)
          .renameNote(
            storageFolder: widget.storageFolder,
            note: note,
            newName: newName,
          );
      ref.invalidate(notesProvider(widget.storageFolder));

      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Note renamed.')));
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showError('Rename failed', error);
    }
  }

  Future<void> _deleteNote(NoteFile note) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete note'),
          content: Text(
            'Delete "${note.name}" from the notes list and Firebase Storage?',
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
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      await ref
          .read(noteServiceProvider)
          .deleteNote(storageFolder: widget.storageFolder, note: note);
      ref.invalidate(notesProvider(widget.storageFolder));

      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Note deleted.')));
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showError('Delete failed', error);
    }
  }

  Future<void> _openNote(NoteFile note) async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return Dialog.fullscreen(child: _NotePreview(note: note));
      },
    );
  }

  Future<void> _downloadNote(NoteFile note) async {
    try {
      await downloadNote(note);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Downloaded ${note.name}.')));
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showError('Download failed', error);
    }
  }

  void _showError(String title, Object error) {
    final message = '$error';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$title: $message'),
        duration: const Duration(seconds: 8),
      ),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    }
    final kilobytes = bytes / 1024;
    if (kilobytes < 1024) {
      return '${kilobytes.toStringAsFixed(1)} KB';
    }
    final megabytes = kilobytes / 1024;
    return '${megabytes.toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final notes = ref.watch(notesProvider(widget.storageFolder));
    final canManageNotes = user?.role == UserRole.admin;

    return AppShell(
      title: '${widget.classroomTitle} Notes',
      leading: IconButton(
        tooltip: 'Back to classrooms',
        onPressed: () => context.go(AppRoutes.classrooms),
        icon: const Icon(Icons.arrow_back),
      ),
      onBack: () async => context.go(AppRoutes.classrooms),
      floatingActionButton: canManageNotes
          ? FloatingActionButton.extended(
              onPressed: _isUploading || user == null
                  ? null
                  : () => _showUploadDialog(user),
              icon: _isUploading
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.upload_file_outlined),
              label: const Text('Upload'),
            )
          : null,
      child: notes.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => EmptyState(
          icon: Icons.error_outline,
          title: 'Could not load notes',
          message: error.toString(),
        ),
        data: (items) {
          if (items.isEmpty) {
            return const EmptyState(
              icon: Icons.folder_copy_outlined,
              title: 'No notes yet',
              message: 'Uploaded class materials will appear here.',
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(24),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final note = items[index];
              return _NoteTile(
                note: note,
                canManage: canManageNotes,
                onOpen: () => _openNote(note),
                onDownload: () => _downloadNote(note),
                onRename: () => _renameNote(note),
                onDelete: () => _deleteNote(note),
              );
            },
            separatorBuilder: (context, index) => const SizedBox(height: 12),
          );
        },
      ),
    );
  }
}

class _NoteTile extends StatelessWidget {
  const _NoteTile({
    required this.note,
    required this.canManage,
    required this.onOpen,
    required this.onDownload,
    required this.onRename,
    required this.onDelete,
  });

  final NoteFile note;
  final bool canManage;
  final VoidCallback onOpen;
  final VoidCallback onDownload;
  final VoidCallback onRename;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final uploadedAt = DateFormat(
      'dd/MM/yyyy, HH:mm:ss',
    ).format(note.createdAt);

    return Card(
      child: ListTile(
        minLeadingWidth: 40,
        leading: Icon(_iconForExtension(note.extension), size: 32),
        title: Text(note.name, maxLines: 2, overflow: TextOverflow.ellipsis),
        subtitle: Text('Uploaded on: $uploadedAt'),
        onTap: onOpen,
        trailing: canManage
            ? PopupMenuButton<_NoteAction>(
                tooltip: 'Note actions',
                onSelected: (action) {
                  switch (action) {
                    case _NoteAction.open:
                      onOpen();
                    case _NoteAction.download:
                      onDownload();
                    case _NoteAction.rename:
                      onRename();
                    case _NoteAction.delete:
                      onDelete();
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: _NoteAction.open,
                    child: ListTile(
                      leading: Icon(Icons.open_in_new),
                      title: Text('Open'),
                    ),
                  ),
                  PopupMenuItem(
                    value: _NoteAction.download,
                    child: ListTile(
                      leading: Icon(Icons.download_outlined),
                      title: Text('Download'),
                    ),
                  ),
                  PopupMenuItem(
                    value: _NoteAction.rename,
                    child: ListTile(
                      leading: Icon(Icons.drive_file_rename_outline),
                      title: Text('Rename'),
                    ),
                  ),
                  PopupMenuItem(
                    value: _NoteAction.delete,
                    child: ListTile(
                      leading: Icon(Icons.delete_outline),
                      title: Text('Delete'),
                    ),
                  ),
                ],
              )
            : IconButton(
                tooltip: 'Download note',
                onPressed: onDownload,
                icon: const Icon(Icons.download_outlined),
              ),
      ),
    );
  }

  IconData _iconForExtension(String extension) {
    return switch (extension) {
      'jpg' || 'jpeg' || 'png' || 'gif' => Icons.image_outlined,
      'pdf' => Icons.picture_as_pdf_outlined,
      'doc' || 'docx' => Icons.description_outlined,
      'mp4' || 'mov' || 'avi' || 'mkv' => Icons.video_file_outlined,
      'ppt' || 'pptx' => Icons.slideshow_outlined,
      'zip' || 'rar' || '7z' || 'tar' || 'gz' => Icons.folder_zip_outlined,
      'txt' => Icons.article_outlined,
      _ => Icons.insert_drive_file_outlined,
    };
  }
}

enum _NoteAction { open, download, rename, delete }

class _NotePreview extends StatelessWidget {
  const _NotePreview({required this.note});

  final NoteFile note;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(note.name)),
      body: switch ((note.isImage, note.isPdf, note.isOfficeDocument)) {
        (true, _, _) => Center(
          child: InteractiveViewer(
            minScale: 0.5,
            maxScale: 5,
            child: Image.network(
              note.link,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) {
                  return child;
                }
                return const Center(child: CircularProgressIndicator());
              },
              errorBuilder: (context, error, stackTrace) {
                return _UnsupportedPreview(
                  note: note,
                  message: 'This image could not be loaded in the app.',
                );
              },
            ),
          ),
        ),
        (_, true, _) => NotePdfPreview(url: note.link),
        (_, _, true) => NoteDocumentPreview(url: note.link),
        _ => _UnsupportedPreview(
          note: note,
          message: 'Preview is not available for this file type yet.',
        ),
      },
    );
  }
}

class _UnsupportedPreview extends StatelessWidget {
  const _UnsupportedPreview({required this.note, required this.message});

  final NoteFile note;
  final String message;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.insert_drive_file_outlined,
                size: 56,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                note.name,
                style: textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(
                'File type: ${note.extension.isEmpty ? 'unknown' : note.extension.toUpperCase()}',
                style: textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
