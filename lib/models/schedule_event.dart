class ScheduleEvent {
  final String id;
  final String homeTeamId;
  final String awayTeamId;
  final String homeTeamName;
  final String awayTeamName;
  final DateTime dateTime;
  final String location;
  final String? notes;
  final String? linkedGameId;

  const ScheduleEvent({
    required this.id,
    required this.homeTeamId,
    required this.awayTeamId,
    required this.homeTeamName,
    required this.awayTeamName,
    required this.dateTime,
    required this.location,
    this.notes,
    this.linkedGameId,
  });

  ScheduleEvent copyWith({
    String? id,
    String? homeTeamId,
    String? awayTeamId,
    String? homeTeamName,
    String? awayTeamName,
    DateTime? dateTime,
    String? location,
    String? notes,
    String? linkedGameId,
  }) {
    return ScheduleEvent(
      id: id ?? this.id,
      homeTeamId: homeTeamId ?? this.homeTeamId,
      awayTeamId: awayTeamId ?? this.awayTeamId,
      homeTeamName: homeTeamName ?? this.homeTeamName,
      awayTeamName: awayTeamName ?? this.awayTeamName,
      dateTime: dateTime ?? this.dateTime,
      location: location ?? this.location,
      notes: notes ?? this.notes,
      linkedGameId: linkedGameId ?? this.linkedGameId,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'homeTeamId': homeTeamId,
      'awayTeamId': awayTeamId,
      'homeTeamName': homeTeamName,
      'awayTeamName': awayTeamName,
      'dateTime': dateTime.toIso8601String(),
      'location': location,
      'notes': notes,
      'linkedGameId': linkedGameId,
    };
  }

  factory ScheduleEvent.fromMap(Map<String, dynamic> map) {
    return ScheduleEvent(
      id: map['id'] as String,
      homeTeamId: map['homeTeamId'] as String,
      awayTeamId: map['awayTeamId'] as String,
      homeTeamName: map['homeTeamName'] as String,
      awayTeamName: map['awayTeamName'] as String,
      dateTime: DateTime.parse(map['dateTime'] as String),
      location: map['location'] as String,
      notes: map['notes'] as String?,
      linkedGameId: map['linkedGameId'] as String?,
    );
  }

  bool get isPast => dateTime.isBefore(DateTime.now());
}
