enum AtBatResult {
  single,      // Coup sûr simple (1B)
  double_,     // Double (2B)
  triple,      // Triple (3B)
  homeRun,     // Coup de circuit (HR)
  strikeoutS,  // Retrait au bâton sur prises (K)
  strikeoutL,  // Retrait au bâton raté (KL)
  walk,        // But sur balles (BB)
  hitByPitch,  // Frappé par le lancer (HBP)
  sacrifice,   // Coup sacrifice (SAC)
  fieldersChoice, // Choix du défenseur (FC)
  groundOut,   // Retrait au sol
  flyOut,      // Retrait en chandelle
  lineOut,     // Retrait en flèche
  doublePlay,  // Double jeu (DP)
  error,       // Erreur (E)
  fieldOut,    // Retiré en défensive (général)
  intentionalWalk, // But sur balles intentionnel (IBB)
}

extension AtBatResultExtension on AtBatResult {
  String get displayName {
    switch (this) {
      case AtBatResult.single: return '1B';
      case AtBatResult.double_: return '2B';
      case AtBatResult.triple: return '3B';
      case AtBatResult.homeRun: return 'HR';
      case AtBatResult.strikeoutS: return 'K';
      case AtBatResult.strikeoutL: return 'KL';
      case AtBatResult.walk: return 'BB';
      case AtBatResult.hitByPitch: return 'HBP';
      case AtBatResult.sacrifice: return 'SAC';
      case AtBatResult.fieldersChoice: return 'FC';
      case AtBatResult.groundOut: return 'GO';
      case AtBatResult.flyOut: return 'FO';
      case AtBatResult.lineOut: return 'LO';
      case AtBatResult.doublePlay: return 'DP';
      case AtBatResult.error: return 'E';
      case AtBatResult.fieldOut: return 'Out';
      case AtBatResult.intentionalWalk: return 'IBB';
    }
  }

  String get fullName {
    switch (this) {
      case AtBatResult.single: return 'Coup sûr simple';
      case AtBatResult.double_: return 'Double';
      case AtBatResult.triple: return 'Triple';
      case AtBatResult.homeRun: return 'Coup de circuit';
      case AtBatResult.strikeoutS: return 'Retrait sur prises';
      case AtBatResult.strikeoutL: return 'Retrait raté (KL)';
      case AtBatResult.walk: return 'But sur balles';
      case AtBatResult.hitByPitch: return 'Frappé par lancer';
      case AtBatResult.sacrifice: return 'Coup sacrifice';
      case AtBatResult.fieldersChoice: return 'Choix défenseur';
      case AtBatResult.groundOut: return 'Retrait au sol';
      case AtBatResult.flyOut: return 'Retrait en chandelle';
      case AtBatResult.lineOut: return 'Retrait en flèche';
      case AtBatResult.doublePlay: return 'Double jeu';
      case AtBatResult.error: return 'Erreur';
      case AtBatResult.fieldOut: return 'Retiré';
      case AtBatResult.intentionalWalk: return 'BSB intentionnel';
    }
  }

  bool get isHit => [
    AtBatResult.single,
    AtBatResult.double_,
    AtBatResult.triple,
    AtBatResult.homeRun,
  ].contains(this);

  bool get isOut => [
    AtBatResult.strikeoutS,
    AtBatResult.strikeoutL,
    AtBatResult.groundOut,
    AtBatResult.flyOut,
    AtBatResult.lineOut,
    AtBatResult.fieldOut,
  ].contains(this);

  bool get isAtBat => ![
    AtBatResult.walk,
    AtBatResult.hitByPitch,
    AtBatResult.sacrifice,
    AtBatResult.intentionalWalk,
  ].contains(this);

  bool get causesOut => isOut || this == AtBatResult.sacrifice;
}

class AtBat {
  final String id;
  final String gameId;
  final String playerId;
  final String teamId;
  final int inning;
  final bool isTopInning;
  final int batterOrder;
  final AtBatResult result;
  final int rbi;
  final int runsScored;
  final int balls;
  final int strikes;
  final String? note;
  final DateTime timestamp;

  const AtBat({
    required this.id,
    required this.gameId,
    required this.playerId,
    required this.teamId,
    required this.inning,
    required this.isTopInning,
    required this.batterOrder,
    required this.result,
    this.rbi = 0,
    this.runsScored = 0,
    this.balls = 0,
    this.strikes = 0,
    this.note,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'gameId': gameId,
      'playerId': playerId,
      'teamId': teamId,
      'inning': inning,
      'isTopInning': isTopInning ? 1 : 0,
      'batterOrder': batterOrder,
      'result': result.index,
      'rbi': rbi,
      'runsScored': runsScored,
      'balls': balls,
      'strikes': strikes,
      'note': note,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory AtBat.fromMap(Map<String, dynamic> map) {
    return AtBat(
      id: map['id'] as String,
      gameId: map['gameId'] as String,
      playerId: map['playerId'] as String,
      teamId: map['teamId'] as String,
      inning: map['inning'] as int,
      isTopInning: (map['isTopInning'] as int) == 1,
      batterOrder: map['batterOrder'] as int,
      result: AtBatResult.values[map['result'] as int],
      rbi: map['rbi'] as int,
      runsScored: map['runsScored'] as int,
      balls: map['balls'] as int,
      strikes: map['strikes'] as int,
      note: map['note'] as String?,
      timestamp: DateTime.parse(map['timestamp'] as String),
    );
  }
}
