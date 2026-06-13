import '../models/app_update.dart';
import 'firebase_database_service.dart';

class AppUpdateService {
  AppUpdateService({FirebaseDatabaseService? databaseService})
    : _databaseService = databaseService ?? FirebaseDatabaseService();

  static const currentVersion = '1.0.0';

  final FirebaseDatabaseService _databaseService;

  Future<AppUpdate?> requiredUpdate() async {
    final value = await _databaseService.get('NUMBERS/VERSION');
    if (value is! Map) {
      return null;
    }

    final update = AppUpdate.fromRealtimeDatabase(value);
    if (!_isValidVersion(update.version) ||
        update.link == null ||
        !const {'http', 'https'}.contains(update.link!.scheme.toLowerCase()) ||
        !isNewerVersion(update.version, currentVersion)) {
      return null;
    }
    return update;
  }
}

bool isNewerVersion(String candidate, String installed) {
  final candidateParts = _versionParts(candidate);
  final installedParts = _versionParts(installed);
  if (candidateParts == null || installedParts == null) {
    return false;
  }

  final length = candidateParts.length > installedParts.length
      ? candidateParts.length
      : installedParts.length;
  for (var index = 0; index < length; index += 1) {
    final candidatePart = index < candidateParts.length
        ? candidateParts[index]
        : 0;
    final installedPart = index < installedParts.length
        ? installedParts[index]
        : 0;
    if (candidatePart != installedPart) {
      return candidatePart > installedPart;
    }
  }
  return false;
}

bool _isValidVersion(String value) => _versionParts(value) != null;

List<int>? _versionParts(String value) {
  final normalized = value.trim();
  if (!RegExp(r'^\d+(?:\.\d+)*$').hasMatch(normalized)) {
    return null;
  }
  return normalized.split('.').map(int.parse).toList();
}
