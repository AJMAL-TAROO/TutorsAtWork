import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/attendance_service.dart';
import '../services/student_service.dart';

final attendanceServiceProvider = Provider<AttendanceService>((ref) {
  return RealtimeDatabaseAttendanceService();
});

final studentServiceProvider = Provider<StudentService>((ref) {
  return RealtimeDatabaseStudentService();
});
