class Player {
  final String id;
  final String teamId;
  final String name;
  final int number;
  final String position;
  final bool isActive;

  const Player({
    required this.id,
    required this.teamId,
    required this.name,
    required this.number,
    required this.position,
    this.isActive = true,
  });

  Player copyWith({
    String? id,
    String? teamId,
    String? name,
    int? number,
    String? position,
    bool? isActive,
  }) {
    return Player(
      id: id ?? this.id,
      teamId: teamId ?? this.teamId,
      name: name ?? this.name,
      number: number ?? this.number,
      position: position ?? this.position,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'teamId': teamId,
      'name': name,
      'number': number,
      'position': position,
      'isActive': isActive ? 1 : 0,
    };
  }

  factory Player.fromMap(Map<String, dynamic> map) {
    return Player(
      id: map['id'] as String,
      teamId: map['teamId'] as String,
      name: map['name'] as String,
      number: map['number'] as int,
      position: map['position'] as String,
      isActive: (map['isActive'] as int) == 1,
    );
  }

  static const List<String> positions = [
    'P',   // Lanceur
    'C',   // Receveur
    '1B',  // Premier but
    '2B',  // Deuxième but
    '3B',  // Troisième but
    'SS',  // Arrêt-court
    'LF',  // Champ gauche
    'CF',  // Champ centre
    'RF',  // Champ droit
    'DH',  // Frappeur désigné
    'UT',  // Utilitaire
  ];

  @override
  String toString() => '$number - $name ($position)';
}
