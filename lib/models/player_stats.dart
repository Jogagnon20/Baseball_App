class PlayerStats {
  final String playerId;
  final String playerName;
  final String teamId;
  final String teamName;
  final int games;
  final int atBats;
  final int hits;
  final int singles;
  final int doubles;
  final int triples;
  final int homeRuns;
  final int rbi;
  final int runs;
  final int walks;
  final int hitByPitch;
  final int strikeouts;
  final int sacrifices;

  const PlayerStats({
    required this.playerId,
    required this.playerName,
    required this.teamId,
    required this.teamName,
    this.games = 0,
    this.atBats = 0,
    this.hits = 0,
    this.singles = 0,
    this.doubles = 0,
    this.triples = 0,
    this.homeRuns = 0,
    this.rbi = 0,
    this.runs = 0,
    this.walks = 0,
    this.hitByPitch = 0,
    this.strikeouts = 0,
    this.sacrifices = 0,
  });

  double get battingAverage =>
      atBats == 0 ? 0.0 : hits / atBats;

  double get onBasePercentage {
    final pa = atBats + walks + hitByPitch + sacrifices;
    if (pa == 0) return 0.0;
    return (hits + walks + hitByPitch) / pa;
  }

  double get sluggingPercentage {
    if (atBats == 0) return 0.0;
    final totalBases = singles + (doubles * 2) + (triples * 3) + (homeRuns * 4);
    return totalBases / atBats;
  }

  double get ops => onBasePercentage + sluggingPercentage;

  String get avgDisplay => battingAverage == 0
      ? '.000'
      : '.${(battingAverage * 1000).round().toString().padLeft(3, '0')}';

  String get obpDisplay => onBasePercentage == 0
      ? '.000'
      : '.${(onBasePercentage * 1000).round().toString().padLeft(3, '0')}';

  String get slgDisplay => sluggingPercentage == 0
      ? '.000'
      : '.${(sluggingPercentage * 1000).round().toString().padLeft(3, '0')}';
}

class TeamStats {
  final String teamId;
  final String teamName;
  final int gamesPlayed;
  final int wins;
  final int losses;
  final int ties;
  final int runsScored;
  final int runsAllowed;
  final int hits;
  final int errors;
  final int homeRuns;

  const TeamStats({
    required this.teamId,
    required this.teamName,
    this.gamesPlayed = 0,
    this.wins = 0,
    this.losses = 0,
    this.ties = 0,
    this.runsScored = 0,
    this.runsAllowed = 0,
    this.hits = 0,
    this.errors = 0,
    this.homeRuns = 0,
  });

  double get winPct =>
      gamesPlayed == 0 ? 0.0 : wins / gamesPlayed;

  int get runDifferential => runsScored - runsAllowed;

  String get winPctDisplay =>
      '.${(winPct * 1000).round().toString().padLeft(3, '0')}';

  String get record => '$wins-$losses${ties > 0 ? '-$ties' : ''}';
}
