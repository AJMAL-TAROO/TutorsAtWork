class Student {
  const Student({
    required this.key,
    required this.fullName,
    required this.email,
    required this.telephone,
    required this.responsibleParty,
    required this.responsiblePartyTelephone,
    required this.password,
    required this.virtualRoomIds,
  });

  factory Student.fromRealtimeDatabase({
    required String key,
    required Map<dynamic, dynamic> data,
  }) {
    return Student(
      key: key,
      fullName: data['FULL_NAME'] as String? ?? 'Unnamed student',
      email: data['EMAIL'] as String? ?? '',
      telephone: data['TEL']?.toString() ?? '',
      responsibleParty: data['R_PARTY']?.toString() ?? '',
      responsiblePartyTelephone: data['R_PARTY_TEL']?.toString() ?? '',
      password: data['PASSWORD']?.toString() ?? '',
      virtualRoomIds: (data['VIRTUAL_ROOMS'] as String? ?? '')
          .split(',')
          .map((room) => int.tryParse(room.trim()))
          .whereType<int>()
          .toList(),
    );
  }

  final String key;
  final String fullName;
  final String email;
  final String telephone;
  final String responsibleParty;
  final String responsiblePartyTelephone;
  final String password;
  final List<int> virtualRoomIds;
}

class StudentDraft {
  const StudentDraft({
    required this.fullName,
    required this.telephone,
    required this.responsibleParty,
    required this.responsiblePartyTelephone,
    required this.email,
    required this.password,
  });

  final String fullName;
  final String telephone;
  final String responsibleParty;
  final String responsiblePartyTelephone;
  final String email;
  final String password;

  Map<String, Object> toRealtimeDatabase({
    required Iterable<int> virtualRoomIds,
  }) {
    return {
      'FULL_NAME': fullName,
      'TEL': telephone,
      'R_PARTY': responsibleParty,
      'R_PARTY_TEL': responsiblePartyTelephone,
      'VIRTUAL_ROOMS': virtualRoomIds.join(','),
      'EMAIL': email,
      'PASSWORD': password,
    };
  }
}
