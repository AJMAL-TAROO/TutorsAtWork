import 'package:flutter_test/flutter_test.dart';
import 'package:taw_app/models/app_user.dart';

void main() {
  test('admin payment and pending APPROVAL values restrict access', () {
    for (final status in ['payment', 'pending']) {
      final user = AppUser.fromRealtimeDatabase(
        key: 'ADMIN_9',
        role: UserRole.admin,
        data: {
          'EMAIL': 'admin@example.com',
          'FULL_NAME': 'Admin',
          'APPROVAL': status.toUpperCase(),
        },
      );

      expect(user.approvalStatus, status);
      expect(user.isAccessRestricted, isTrue);
    }
  });

  test('legacy APRROVAL spelling remains supported', () {
    final user = AppUser.fromRealtimeDatabase(
      key: 'ADMIN_9',
      role: UserRole.admin,
      data: {'APRROVAL': 'payment'},
    );

    expect(user.isAccessRestricted, isTrue);
  });

  test('students and active admins are not restricted', () {
    final student = AppUser.fromRealtimeDatabase(
      key: 'STUDENT_1',
      role: UserRole.student,
      data: {'APPROVAL': 'payment'},
    );
    final admin = AppUser.fromRealtimeDatabase(
      key: 'ADMIN_9',
      role: UserRole.admin,
      data: {'APPROVAL': 'active'},
    );

    expect(student.isAccessRestricted, isFalse);
    expect(admin.isAccessRestricted, isFalse);
  });
}
