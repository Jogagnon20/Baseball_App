import 'package:flutter/foundation.dart';
import '../models/at_bat.dart';
import '../models/game.dart';
import '../models/player_stats.dart';
import '../database/database_helper.dart';

class StatsProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper();

  List<PlayerStats> _playerStats = [];
  List<TeamStats> _teamStats = [];
  bool _isLoading = false;

  List<PlayerStats> get playerStats => List.unmodifiable(_playerStats);
  List<TeamStats> get teamStats => List.unmodifiable(_teamStats);
  bool get isLoading => _isLoading;

  Future<void> computeStats() async {
    _isLoading = true;
    notifyListeners();

    final games = await _db.getGames(status: GameStatus.completed);
    final allTeams = await _db.getTeams();

    // Map teamId -> TeamStats accumulator
    final teamMap = <String, _TeamAccumulator>{};
    // Map playerId -> PlayerStats accumulator
    final playerMap = <String, _PlayerAccumulator>{};

    for (final game in games) {
      final atBats = await _db.getAtBats(game.id);

      // Team wins/losses
      final homeId = game.homeTeamId;
      final awayId = game.awayTeamId;

      teamMap.putIfAbsent(homeId, () => _TeamAccumulator(
        teamId: homeId,
        teamName: game.homeTeamName,
      ));
      teamMap.putIfAbsent(awayId, () => _TeamAccumulator(
        teamId: awayId,
        teamName: game.awayTeamName,
      ));

      teamMap[homeId]!.gamesPlayed++;
      teamMap[awayId]!.gamesPlayed++;
      teamMap[homeId]!.runsScored += game.homeScore;
      teamMap[homeId]!.runsAllowed += game.awayScore;
      teamMap[awayId]!.runsScored += game.awayScore;
      teamMap[awayId]!.runsAllowed += game.homeScore;
      teamMap[homeId]!.hits += game.homeHits;
      teamMap[awayId]!.hits += game.awayHits;
      teamMap[homeId]!.errors += game.homeErrors;
      teamMap[awayId]!.errors += game.awayErrors;

      if (game.homeScore > game.awayScore) {
        teamMap[homeId]!.wins++;
        teamMap[awayId]!.losses++;
      } else if (game.awayScore > game.homeScore) {
        teamMap[awayId]!.wins++;
        teamMap[homeId]!.losses++;
      } else {
        teamMap[homeId]!.ties++;
        teamMap[awayId]!.ties++;
      }

      // Player at-bat stats
      for (final ab in atBats) {
        final pid = ab.playerId;
        final teamName = ab.teamId == homeId
            ? game.homeTeamName
            : game.awayTeamName;

        playerMap.putIfAbsent(pid, () => _PlayerAccumulator(
          playerId: pid,
          teamId: ab.teamId,
          teamName: teamName,
        ));

        final acc = playerMap[pid]!;
        acc.rbi += ab.rbi;
        acc.runs += ab.runsScored;

        if (ab.result.isAtBat) acc.atBats++;

        switch (ab.result) {
          case AtBatResult.single:
            acc.hits++; acc.singles++;
          case AtBatResult.double_:
            acc.hits++; acc.doubles++;
          case AtBatResult.triple:
            acc.hits++; acc.triples++;
          case AtBatResult.homeRun:
            acc.hits++; acc.homeRuns++;
            teamMap[ab.teamId]?.homeRuns++;
          case AtBatResult.strikeoutS:
          case AtBatResult.strikeoutL:
            acc.strikeouts++;
          case AtBatResult.walk:
          case AtBatResult.intentionalWalk:
            acc.walks++;
          case AtBatResult.hitByPitch:
            acc.hitByPitch++;
          case AtBatResult.sacrifice:
            acc.sacrifices++;
          default:
            break;
        }
      }
    }

    // Get player names from DB
    for (final pid in playerMap.keys) {
      final player = await _db.getPlayer(pid);
      if (player != null) {
        playerMap[pid]!.playerName = player.name;
        // Count games for player
        final pAtBats = await _db.getPlayerAtBats(pid);
        final gameIds = pAtBats.map((a) => a.gameId).toSet();
        playerMap[pid]!.games = gameIds.length;
      }
    }

    _playerStats = playerMap.values
        .map((acc) => PlayerStats(
              playerId: acc.playerId,
              playerName: acc.playerName,
              teamId: acc.teamId,
              teamName: acc.teamName,
              games: acc.games,
              atBats: acc.atBats,
              hits: acc.hits,
              singles: acc.singles,
              doubles: acc.doubles,
              triples: acc.triples,
              homeRuns: acc.homeRuns,
              rbi: acc.rbi,
              runs: acc.runs,
              walks: acc.walks,
              hitByPitch: acc.hitByPitch,
              strikeouts: acc.strikeouts,
              sacrifices: acc.sacrifices,
            ))
        .toList()
      ..sort((a, b) => b.battingAverage.compareTo(a.battingAverage));

    _teamStats = teamMap.values
        .map((acc) => TeamStats(
              teamId: acc.teamId,
              teamName: acc.teamName,
              gamesPlayed: acc.gamesPlayed,
              wins: acc.wins,
              losses: acc.losses,
              ties: acc.ties,
              runsScored: acc.runsScored,
              runsAllowed: acc.runsAllowed,
              hits: acc.hits,
              errors: acc.errors,
              homeRuns: acc.homeRuns,
            ))
        .toList()
      ..sort((a, b) => b.wins.compareTo(a.wins));

    _isLoading = false;
    notifyListeners();
  }

  List<PlayerStats> statsForTeam(String teamId) =>
      _playerStats.where((s) => s.teamId == teamId).toList();
}

class _TeamAccumulator {
  final String teamId;
  String teamName;
  int gamesPlayed = 0;
  int wins = 0;
  int losses = 0;
  int ties = 0;
  int runsScored = 0;
  int runsAllowed = 0;
  int hits = 0;
  int errors = 0;
  int homeRuns = 0;
  _TeamAccumulator({required this.teamId, required this.teamName});
}

class _PlayerAccumulator {
  final String playerId;
  String playerName = '';
  final String teamId;
  String teamName;
  int games = 0;
  int atBats = 0;
  int hits = 0;
  int singles = 0;
  int doubles = 0;
  int triples = 0;
  int homeRuns = 0;
  int rbi = 0;
  int runs = 0;
  int walks = 0;
  int hitByPitch = 0;
  int strikeouts = 0;
  int sacrifices = 0;
  _PlayerAccumulator({
    required this.playerId,
    required this.teamId,
    required this.teamName,
  });
}
