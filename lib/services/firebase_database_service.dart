import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/firebase_options.dart';

class FirebaseDatabaseService {
  FirebaseDatabaseService({http.Client? client})
    : _client = client ?? http.Client();

  final http.Client _client;

  String get students => 'STUDENTS';
  String get admins => 'ADMIN';
  String get classrooms => 'CLASSROOMS';

  String noteCounter(int classroomId) {
    return 'NUMBERS/ID_CLASSROOM_${classroomId}_NOTES/NUMBER';
  }

  String homeworkCounter(int classroomId) {
    return 'NUMBERS/ID_CLASSROOM_${classroomId}_HOMEWORK/NUMBER';
  }

  String notesFolder(String storageFolder) {
    return storageFolder;
  }

  Future<Object?> get(String path) async {
    final response = await _client.get(_databaseUri(path));
    _ensureSuccess(response, 'read $path');
    if (response.body.trim() == 'null' || response.body.isEmpty) {
      return null;
    }
    return jsonDecode(response.body);
  }

  Future<void> set(String path, Object? value) async {
    final response = await _client.put(
      _databaseUri(path),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode(value),
    );
    _ensureSuccess(response, 'write $path');
  }

  Future<void> update(String path, Map<String, Object?> value) async {
    final response = await _client.patch(
      _databaseUri(path),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode(value),
    );
    _ensureSuccess(response, 'update $path');
  }

  Future<void> remove(String path) async {
    final response = await _client.delete(_databaseUri(path));
    _ensureSuccess(response, 'delete $path');
  }

  Future<int> reserveNextCounter(
    String path, {
    int minimumCurrentValue = 1,
    int maxAttempts = 8,
  }) async {
    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      final readResponse = await _client.get(
        _databaseUri(path),
        headers: const {'X-Firebase-ETag': 'true'},
      );
      _ensureSuccess(readResponse, 'read counter $path');
      final currentValue =
          int.tryParse(
            readResponse.body.trim() == 'null' ? '' : readResponse.body,
          ) ??
          minimumCurrentValue;
      final nextValue =
          (currentValue < minimumCurrentValue
              ? minimumCurrentValue
              : currentValue) +
          1;
      final etag = readResponse.headers['etag'] ?? '*';
      final writeResponse = await _client.put(
        _databaseUri(path),
        headers: {'Content-Type': 'application/json', 'if-match': etag},
        body: jsonEncode(nextValue),
      );
      if (writeResponse.statusCode == 412) {
        continue;
      }
      _ensureSuccess(writeResponse, 'reserve counter $path');
      return nextValue;
    }
    throw StateError('Could not reserve a unique file ID. Please try again.');
  }

  Stream<Object?> watch(String path) async* {
    var hasPrevious = false;
    Object? previous;
    while (true) {
      final current = await get(path);
      final currentJson = jsonEncode(current);
      if (!hasPrevious || jsonEncode(previous) != currentJson) {
        hasPrevious = true;
        previous = current;
        yield current;
      }
      await Future<void>.delayed(const Duration(seconds: 3));
    }
  }

  Uri _databaseUri(String path) {
    final normalizedPath = path
        .split('/')
        .where((part) => part.isNotEmpty)
        .map(Uri.encodeComponent)
        .join('/');
    return Uri.parse(
      '${DefaultFirebaseOptions.databaseURL}/$normalizedPath.json',
    );
  }

  void _ensureSuccess(http.Response response, String action) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }
    throw StateError(
      'Firebase Realtime Database failed to $action: '
      '${response.statusCode} ${response.body}',
    );
  }
}
