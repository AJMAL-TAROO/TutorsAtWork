import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/firebase_options.dart';

class FirebaseDatabaseService {
  FirebaseDatabaseService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  String get students => 'STUDENTS';
  String get admins => 'ADMIN';
  String get classrooms => 'CLASSROOMS';

  String noteCounter(int classroomId) {
    return 'NUMBERS/ID_CLASSROOM_${classroomId}_NOTES/NUMBER';
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

  Stream<Object?> watch(String path) async* {
    Object? previous;
    while (true) {
      final current = await get(path);
      final currentJson = jsonEncode(current);
      if (jsonEncode(previous) != currentJson) {
        previous = current;
        yield current;
      }
      await Future<void>.delayed(const Duration(seconds: 3));
    }
  }

  Uri _databaseUri(String path) {
    final normalizedPath = path.split('/').where((part) => part.isNotEmpty).join('/');
    return Uri.parse('${DefaultFirebaseOptions.databaseURL}/$normalizedPath.json');
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
