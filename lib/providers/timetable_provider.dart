import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/timetable_session.dart';
import '../services/timetable_service.dart';
import 'auth_provider.dart';

final timetableServiceProvider = Provider<TimetableService>((ref) {
  return RealtimeDatabaseTimetableService();
});

final timetableProvider = StreamProvider<List<TimetableSession>>((ref) {
  final user = ref.watch(currentUserProvider);
  final service = ref.watch(timetableServiceProvider);
  if (user == null) {
    return Stream.value(const <TimetableSession>[]);
  }
  return service.watchSessionsForAdmin(user.key);
});
