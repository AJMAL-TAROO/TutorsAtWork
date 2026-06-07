import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import '../config/app_config.dart';
import '../models/app_user.dart';
import 'firebase_database_service.dart';

class ExamAiService {
  ExamAiService({FirebaseDatabaseService? databaseService})
    : _databaseService = databaseService ?? FirebaseDatabaseService();

  static const sessionDuration = Duration(minutes: 30);

  final FirebaseDatabaseService _databaseService;
  final _random = Random.secure();

  Future<Uri> createSessionUri(AppUser user) async {
    if (user.role != UserRole.admin) {
      throw StateError('Exam AI is available to tutors only.');
    }

    final token = _createToken();
    final expiresAt = DateTime.now().toUtc().add(sessionDuration);

    await _databaseService.set('EXAM_AI/SESSIONS/$token', {
      'ADMIN_KEY': user.key,
      'EXPIRES_AT': expiresAt.toIso8601String(),
      'EXPIRES_AT_MS': expiresAt.millisecondsSinceEpoch,
    });

    return Uri.parse(
      AppConfig.examAiBaseUrl,
    ).replace(queryParameters: {'session': token});
  }

  String _createToken() {
    final bytes = Uint8List(32);
    for (var i = 0; i < bytes.length; i += 1) {
      bytes[i] = _random.nextInt(256);
    }
    return base64UrlEncode(bytes).replaceAll('=', '');
  }
}
