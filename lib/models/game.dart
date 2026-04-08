import 'dart:convert';

enum GameStatus { inProgress, completed, cancelled }

class InningScore {
  final int inning;
  final int homeRuns;
  final int awayRuns;
  final int homeHits;
  final int awayHits;
  final int homeErrors;
  final int awayErrors;

  const InningScore({
    required this.inning,
    this.homeRuns = 0,
    this.awayRuns = 0,
    this.homeHits = 0,
    this.awayHits = 0,
    this.homeErrors = 0,
    this.awayErrors = 0,
  });

  InningScore copyWith({
    int? homeRuns,
    int? awayRuns,
    int? homeHits,
    int? awayHits,
    int? homeErrors,
    int? awayErrors,
  }) {
    return InningScore(
      inning: inning,
      homeRuns: homeRuns ?? this.homeRuns,
      awayRuns: awayRuns ?? this.awayRuns,
      homeHits: homeHits ?? this.homeHits,
      awayHits: awayHits ?? this.awayHits,
      homeErrors: homeErrors ?? this.homeErrors,
      awayErrors: awayErrors ?? this.awayErrors,
    );
  }

  Map<String, dynamic> toMap() => {
    'inning': inning,
    'homeRuns': homeRuns,
    'awayRuns': awayRuns,
    'homeHits': homeHits,
    'awayHits': awayHits,
    'homeErrors': homeErrors,
    'awayErrors': awayErrors,
  };

  factory InningScore.fromMap(Map<String, dynamic> map) => InningScore(
    inning: map['inning'] as int,
    homeRuns: map['homeRuns'] as int? ?? 0,
    awayRuns: map['awayRuns'] as int? ?? 0,
    homeHits: map['homeHits'] as int? ?? 0,
    awayHits: map['awayHits'] as int? ?? 0,
    homeErrors: map['homeErrors'] as int? ?? 0,
    awayErrors: map['awayErrors'] as int? ?? 0,
  );
}

class Game {
  final String id;
  final String homeTeamId;
  final String awayTeamId;
  final String homeTeamName;
  final String awayTeamName;
  final DateTime gameDate;
  final String location;
  final GameStatus status;
  final int currentInning;
  final bool isTopInning;
  final int outs;
  final List<InningScore> innings;
  final List<String> homeLineup;   // Player IDs in order
  final List<String> awayLineup;   // Player IDs in order
  final int currentHomeBatter;     // Index in lineup
  final int currentAwayBatter;     // Index in lineup
  final bool runner1st;
  final bool runner2nd;
  final bool runner3rd;
  final String? notes;
  final int totalInnings;

  const Game({
    required this.id,
    required this.homeTeamId,
    required this.awayTeamId,
    required this.homeTeamName,
    required this.awayTeamName,
    required this.gameDate,
    required this.location,
    this.status = GameStatus.inProgress,
    this.currentInning = 1,
    this.isTopInning = true,
    this.outs = 0,
    this.innings = const [],
    this.homeLineup = const [],
    this.awayLineup = const [],
    this.currentHomeBatter = 0,
    this.currentAwayBatter = 0,
    this.runner1st = false,
    this.runner2nd = false,
    this.runner3rd = false,
    this.notes,
    this.totalInnings = 9,
  });

  int get homeScore => innings.fold(0, (sum, i) => sum + i.homeRuns);
  int get awayScore => innings.fold(0, (sum, i) => sum + i.awayRuns);
  int get homeHits => innings.fold(0, (sum, i) => sum + i.homeHits);
  int get awayHits => innings.fold(0, (sum, i) => sum + i.awayHits);
  int get homeErrors => innings.fold(0, (sum, i) => sum + i.homeErrors);
  int get awayErrors => innings.fold(0, (sum, i) => sum + i.awayErrors);

  InningScore? inningScore(int inning) {
    try {
      return innings.firstWhere((i) => i.inning == inning);
    } catch (_) {
      return null;
    }
  }

  int get currentBatterIndex =>
      isTopInning ? currentAwayBatter : currentHomeBatter;

  String get currentTeamId => isTopInning ? awayTeamId : homeTeamId;
  List<String> get currentLineup => isTopInning ? awayLineup : homeLineup;

  String get inningDisplay {
    if (status == GameStatus.completed) return 'Terminé';
    final half = isTopInning ? '▲' : '▼';
    return '$half$currentInning';
  }

  Game copyWith({
    String? id,
    String? homeTeamId,
    String? awayTeamId,
    String? homeTeamName,
    String? awayTeamName,
    DateTime? gameDate,
    String? location,
    GameStatus? status,
    int? currentInning,
    bool? isTopInning,
    int? outs,
    List<InningScore>? innings,
    List<String>? homeLineup,
    List<String>? awayLineup,
    int? currentHomeBatter,
    int? currentAwayBatter,
    bool? runner1st,
    bool? runner2nd,
    bool? runner3rd,
    String? notes,
    int? totalInnings,
  }) {
    return Game(
      id: id ?? this.id,
      homeTeamId: homeTeamId ?? this.homeTeamId,
      awayTeamId: awayTeamId ?? this.awayTeamId,
      homeTeamName: homeTeamName ?? this.homeTeamName,
      awayTeamName: awayTeamName ?? this.awayTeamName,
      gameDate: gameDate ?? this.gameDate,
      location: location ?? this.location,
      status: status ?? this.status,
      currentInning: currentInning ?? this.currentInning,
      isTopInning: isTopInning ?? this.isTopInning,
      outs: outs ?? this.outs,
      innings: innings ?? this.innings,
      homeLineup: homeLineup ?? this.homeLineup,
      awayLineup: awayLineup ?? this.awayLineup,
      currentHomeBatter: currentHomeBatter ?? this.currentHomeBatter,
      currentAwayBatter: currentAwayBatter ?? this.currentAwayBatter,
      runner1st: runner1st ?? this.runner1st,
      runner2nd: runner2nd ?? this.runner2nd,
      runner3rd: runner3rd ?? this.runner3rd,
      notes: notes ?? this.notes,
      totalInnings: totalInnings ?? this.totalInnings,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'homeTeamId': homeTeamId,
      'awayTeamId': awayTeamId,
      'homeTeamName': homeTeamName,
      'awayTeamName': awayTeamName,
      'gameDate': gameDate.toIso8601String(),
      'location': location,
      'status': status.index,
      'currentInning': currentInning,
      'isTopInning': isTopInning ? 1 : 0,
      'outs': outs,
      'innings': jsonEncode(innings.map((i) => i.toMap()).toList()),
      'homeLineup': jsonEncode(homeLineup),
      'awayLineup': jsonEncode(awayLineup),
      'currentHomeBatter': currentHomeBatter,
      'currentAwayBatter': currentAwayBatter,
      'runner1st': runner1st ? 1 : 0,
      'runner2nd': runner2nd ? 1 : 0,
      'runner3rd': runner3rd ? 1 : 0,
      'notes': notes,
      'totalInnings': totalInnings,
    };
  }

  factory Game.fromMap(Map<String, dynamic> map) {
    final inningsJson = jsonDecode(map['innings'] as String) as List;
    final homeLineupJson = jsonDecode(map['homeLineup'] as String) as List;
    final awayLineupJson = jsonDecode(map['awayLineup'] as String) as List;

    return Game(
      id: map['id'] as String,
      homeTeamId: map['homeTeamId'] as String,
      awayTeamId: map['awayTeamId'] as String,
      homeTeamName: map['homeTeamName'] as String,
      awayTeamName: map['awayTeamName'] as String,
      gameDate: DateTime.parse(map['gameDate'] as String),
      location: map['location'] as String,
      status: GameStatus.values[map['status'] as int],
      currentInning: map['currentInning'] as int,
      isTopInning: (map['isTopInning'] as int) == 1,
      outs: map['outs'] as int,
      innings: inningsJson
          .map((i) => InningScore.fromMap(i as Map<String, dynamic>))
          .toList(),
      homeLineup: homeLineupJson.cast<String>(),
      awayLineup: awayLineupJson.cast<String>(),
      currentHomeBatter: map['currentHomeBatter'] as int,
      currentAwayBatter: map['currentAwayBatter'] as int,
      runner1st: (map['runner1st'] as int) == 1,
      runner2nd: (map['runner2nd'] as int) == 1,
      runner3rd: (map['runner3rd'] as int) == 1,
      notes: map['notes'] as String?,
      totalInnings: map['totalInnings'] as int? ?? 9,
    );
  }
}
