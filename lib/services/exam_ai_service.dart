import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import '../config/app_config.dart';
import '../models/app_user.dart';
import 'firebase_database_service.dart';

class ExamAiService {
  ExamAiService({
    FirebaseDatabaseService? databaseService,
    DateTime Function()? now,
  }) : _databaseService = databaseService ?? FirebaseDatabaseService(),
       _now = now ?? DateTime.now;

  static const sessionDuration = Duration(minutes: 30);
  static const _sessionsPath = 'EXAM_AI/SESSIONS';

  final FirebaseDatabaseService _databaseService;
  final DateTime Function() _now;
  final _random = Random.secure();

  Future<Uri> createSessionUri(AppUser user) async {
    if (user.role != UserRole.admin) {
      throw StateError('Exam AI is available to tutors only.');
    }

    final token = _createToken();
    final now = _now().toUtc();
    final expiresAt = now.add(sessionDuration);
    final session = {
      'ADMIN_KEY': user.key,
      'EXPIRES_AT': expiresAt.toIso8601String(),
      'EXPIRES_AT_MS': expiresAt.millisecondsSinceEpoch,
    };

    try {
      final existingSessions = await _databaseService.get(_sessionsPath);
      final updates = <String, Object?>{token: session};

      if (existingSessions is Map) {
        for (final entry in existingSessions.entries) {
          final existingToken = entry.key.toString();
          if (_isExpiredOrInvalid(entry.value, now.millisecondsSinceEpoch)) {
            updates[existingToken] = null;
          }
        }
      }

      await _databaseService.update(_sessionsPath, updates);
    } catch (_) {
      // Cleanup must never prevent a tutor from opening a new valid session.
      await _databaseService.set('$_sessionsPath/$token', session);
    }

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

  bool _isExpiredOrInvalid(Object? value, int nowMs) {
    if (value is! Map) {
      return true;
    }

    final numericExpiry = int.tryParse('${value['EXPIRES_AT_MS'] ?? ''}');
    if (numericExpiry != null) {
      return numericExpiry <= nowMs;
    }

    final textExpiry = DateTime.tryParse('${value['EXPIRES_AT'] ?? ''}');
    return textExpiry == null ||
        textExpiry.toUtc().millisecondsSinceEpoch <= nowMs;
  }
}
