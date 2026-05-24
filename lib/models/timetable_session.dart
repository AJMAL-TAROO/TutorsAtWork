class TimetableSession {
  const TimetableSession({
    required this.day,
    required this.timeRange,
    required this.classroomTitle,
  });

  final int day;
  final String timeRange;
  final String classroomTitle;

  String get dayName {
    return switch (day) {
      1 => 'Monday',
      2 => 'Tuesday',
      3 => 'Wednesday',
      4 => 'Thursday',
      5 => 'Friday',
      6 => 'Saturday',
      7 => 'Sunday',
      _ => 'Day $day',
    };
  }
}
