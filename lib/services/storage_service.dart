import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../config/firebase_options.dart';

class StorageService {
  StorageService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  String classroomNotesFolder(String classroomId) {
    return '${classroomId}_NOTES';
  }

  String noteFile(String storageFolder, int noteId) {
    return '$storageFolder/$noteId';
  }

  Future<String> uploadNoteFile({
    required String storageFolder,
    required int noteId,
    required List<int> bytes,
    required String fileName,
    required String? contentType,
  }) async {
    final objectPath = noteFile(storageFolder, noteId);
    final token = _downloadToken();
    final headers = {
      'Content-Disposition': 'inline; filename="$fileName"',
      'x-goog-meta-firebaseStorageDownloadTokens': token,
    };
    if (contentType != null) {
      headers['Content-Type'] = contentType;
    }
    final response = await _client.post(
      _storageUri(objectPath),
      headers: headers,
      body: Uint8List.fromList(bytes),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError(
        'Firebase Storage upload failed: ${response.statusCode} ${response.body}',
      );
    }

    return downloadUrl(objectPath, token);
  }

  Future<void> deleteNoteFile(String storageFolder, int noteId) async {
    final response = await _client.delete(
      _objectUri(noteFile(storageFolder, noteId)),
    );
    if (response.statusCode == 404) {
      return;
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError(
        'Firebase Storage delete failed: ${response.statusCode} ${response.body}',
      );
    }
  }

  String downloadUrl(String objectPath, String token) {
    final encodedPath = Uri.encodeComponent(objectPath);
    return 'https://firebasestorage.googleapis.com/v0/b/'
        '${DefaultFirebaseOptions.storageBucket}/o/$encodedPath'
        '?alt=media&token=$token';
  }

  Uri _storageUri(String objectPath) {
    return Uri.https(
      'firebasestorage.googleapis.com',
      '/v0/b/${DefaultFirebaseOptions.storageBucket}/o',
      {
        'uploadType': 'media',
        'name': objectPath,
      },
    );
  }

  Uri _objectUri(String objectPath) {
    return Uri.https(
      'firebasestorage.googleapis.com',
      '/v0/b/${DefaultFirebaseOptions.storageBucket}/o/${Uri.encodeComponent(objectPath)}',
    );
  }

  String _downloadToken() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return base64Url.encode(bytes).replaceAll('=', '');
  }
}
