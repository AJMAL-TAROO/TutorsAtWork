import 'package:flutter_test/flutter_test.dart';
import 'package:taw_app/services/app_update_service.dart';

void main() {
  group('isNewerVersion', () {
    test('detects newer semantic versions', () {
      expect(isNewerVersion('1.0.1', '1.0.0'), isTrue);
      expect(isNewerVersion('1.1.0', '1.0.9'), isTrue);
      expect(isNewerVersion('2.0.0', '1.99.99'), isTrue);
      expect(isNewerVersion('1.0.10', '1.0.9'), isTrue);
    });

    test('does not require equal or older versions', () {
      expect(isNewerVersion('1.0.0', '1.0.0'), isFalse);
      expect(isNewerVersion('1.0', '1.0.0'), isFalse);
      expect(isNewerVersion('0.9.9', '1.0.0'), isFalse);
    });

    test('rejects malformed version values', () {
      expect(isNewerVersion('version 2', '1.0.0'), isFalse);
      expect(isNewerVersion('1.0.0-beta', '1.0.0'), isFalse);
      expect(isNewerVersion('', '1.0.0'), isFalse);
    });
  });
}
