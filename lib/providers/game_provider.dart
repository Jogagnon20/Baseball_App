import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/game.dart';
import '../models/at_bat.dart';
import '../models/player.dart';
import '../database/database_helper.dart';

class GameProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper();
  final _uuid = const Uuid();

  List<Game> _games = [];
  Game? _activeGame;
  List<AtBat> _activeAtBats = [];
  bool _isLoading = false;

  List<Game> get games => List.unmodifiable(_games);
  List<Game> get completedGames =>
      _games.where((g) => g.status == GameStatus.completed).toList();
  List<Game> get inProgressGames =>
      _games.where((g) => g.status == GameStatus.inProgress).toList();
  Game? get activeGame => _activeGame;
  List<AtBat> get activeAtBats => List.unmodifiable(_activeAtBats);
  bool get isLoading => _isLoading;

  Future<void> loadGames() async {
    _isLoading = true;
    notifyListeners();
    _games = await _db.getGames();
    _isLoading = false;
    notifyListeners();
  }

  Future<Game> createGame({
    required String homeTeamId,
    required String awayTeamId,
    required String homeTeamName,
    required String awayTeamName,
    required DateTime gameDate,
    required String location,
    required List<String> homeLineup,
    required List<String> awayLineup,
    int totalInnings = 9,
  }) async {
    final game = Game(
      id: _uuid.v4(),
      homeTeamId: homeTeamId,
      awayTeamId: awayTeamId,
      homeTeamName: homeTeamName,
      awayTeamName: awayTeamName,
      gameDate: gameDate,
      location: location,
      homeLineup: homeLineup,
      awayLineup: awayLineup,
      totalInnings: totalInnings,
    );
    await _db.insertGame(game);
    _games.insert(0, game);
    _activeGame = game;
    _activeAtBats = [];
    notifyListeners();
    return game;
  }

  Future<void> loadActiveGame(String gameId) async {
    _activeGame = await _db.getGame(gameId);
    _activeAtBats = await _db.getAtBats(gameId);
    notifyListeners();
  }

  Future<void> recordAtBat({
    required String playerId,
    required String teamId,
    required AtBatResult result,
    required int balls,
    required int strikes,
    int rbi = 0,
    int runsScored = 0,
    String? note,
  }) async {
    if (_activeGame == null) return;

    final game = _activeGame!;
    final atBat = AtBat(
      id: _uuid.v4(),
      gameId: game.id,
      playerId: playerId,
      teamId: teamId,
      inning: game.currentInning,
      isTopInning: game.isTopInning,
      batterOrder: game.currentBatterIndex,
      result: result,
      rbi: rbi,
      runsScored: runsScored,
      balls: balls,
      strikes: strikes,
      note: note,
      timestamp: DateTime.now(),
    );

    await _db.insertAtBat(atBat);
    _activeAtBats.add(atBat);

    // Update game state
    Game updatedGame = _updateGameAfterAtBat(game, atBat);

    await _db.updateGame(updatedGame);
    _activeGame = updatedGame;

    final idx = _games.indexWhere((g) => g.id == game.id);
    if (idx != -1) _games[idx] = updatedGame;

    notifyListeners();
  }

  Game _updateGameAfterAtBat(Game game, AtBat atBat) {
    // Update inning score
    final innings = List<InningScore>.from(game.innings);
    int inningIdx = innings.indexWhere((i) => i.inning == game.currentInning);
    if (inningIdx == -1) {
      innings.add(InningScore(inning: game.currentInning));
      inningIdx = innings.length - 1;
    }

    final isHome = !game.isTopInning;
    final isHit = atBat.result.isHit;

    innings[inningIdx] = innings[inningIdx].copyWith(
      homeRuns: isHome ? innings[inningIdx].homeRuns + atBat.runsScored : null,
      awayRuns: !isHome ? innings[inningIdx].awayRuns + atBat.runsScored : null,
      homeHits: isHome && isHit ? innings[inningIdx].homeHits + 1 : null,
      awayHits: !isHome && isHit ? innings[inningIdx].awayHits + 1 : null,
    );

    // Advance batter in lineup
    final isOutcome = atBat.result.causesOut || atBat.result.isOut;
    final newOuts = isOutcome
        ? game.outs + (atBat.result == AtBatResult.doublePlay ? 2 : 1)
        : game.outs;

    bool newIsTopInning = game.isTopInning;
    int newInning = game.currentInning;
    int newOuts2 = newOuts;
    bool r1 = game.runner1st;
    bool r2 = game.runner2nd;
    bool r3 = game.runner3rd;

    // Update runners based on result
    final runners = _advanceRunners(
      result: atBat.result,
      r1: r1, r2: r2, r3: r3,
    );
    r1 = runners['r1']!;
    r2 = runners['r2']!;
    r3 = runners['r3']!;

    if (newOuts2 >= 3) {
      // End of half inning
      newOuts2 = 0;
      r1 = false;
      r2 = false;
      r3 = false;
      if (game.isTopInning) {
        newIsTopInning = false;
      } else {
        newIsTopInning = true;
        newInning = game.currentInning + 1;
      }
    }

    // Advance batter index
    int newHomeBatter = game.currentHomeBatter;
    int newAwayBatter = game.currentAwayBatter;
    if (game.isTopInning) {
      newAwayBatter = game.awayLineup.isEmpty
          ? 0
          : (game.currentAwayBatter + 1) % game.awayLineup.length;
    } else {
      newHomeBatter = game.homeLineup.isEmpty
          ? 0
          : (game.currentHomeBatter + 1) % game.homeLineup.length;
    }

    return game.copyWith(
      innings: innings,
      outs: newOuts2,
      isTopInning: newIsTopInning,
      currentInning: newInning,
      currentHomeBatter: newHomeBatter,
      currentAwayBatter: newAwayBatter,
      runner1st: r1,
      runner2nd: r2,
      runner3rd: r3,
    );
  }

  Map<String, bool> _advanceRunners({
    required AtBatResult result,
    required bool r1,
    required bool r2,
    required bool r3,
  }) {
    switch (result) {
      case AtBatResult.homeRun:
        return {'r1': false, 'r2': false, 'r3': false};
      case AtBatResult.triple:
        return {'r1': false, 'r2': false, 'r3': true};
      case AtBatResult.double_:
        return {'r1': false, 'r2': r1, 'r3': r2 || r3};
      case AtBatResult.single:
        return {'r1': true, 'r2': r1, 'r3': r2};
      case AtBatResult.walk:
      case AtBatResult.hitByPitch:
      case AtBatResult.intentionalWalk:
        // Force advances only
        if (r1 && r2 && r3) return {'r1': true, 'r2': true, 'r3': true};
        if (r1 && r2) return {'r1': true, 'r2': true, 'r3': r3};
        if (r1) return {'r1': true, 'r2': true, 'r3': r3};
        return {'r1': true, 'r2': r2, 'r3': r3};
      case AtBatResult.sacrifice:
        // Runner on 3rd scores, others advance
        return {'r1': r1, 'r2': r1, 'r3': r2};
      case AtBatResult.fieldersChoice:
        return {'r1': true, 'r2': r1, 'r3': r2};
      case AtBatResult.error:
        return {'r1': true, 'r2': r1, 'r3': r2};
      default:
        return {'r1': r1, 'r2': r2, 'r3': r3};
    }
  }

  Future<void> updateRunners({
    required bool r1,
    required bool r2,
    required bool r3,
  }) async {
    if (_activeGame == null) return;
    final updated = _activeGame!.copyWith(
      runner1st: r1,
      runner2nd: r2,
      runner3rd: r3,
    );
    await _db.updateGame(updated);
    _activeGame = updated;
    final idx = _games.indexWhere((g) => g.id == updated.id);
    if (idx != -1) _games[idx] = updated;
    notifyListeners();
  }

  Future<void> addError({required bool isHome}) async {
    if (_activeGame == null) return;
    final game = _activeGame!;
    final innings = List<InningScore>.from(game.innings);
    int inningIdx = innings.indexWhere((i) => i.inning == game.currentInning);
    if (inningIdx == -1) {
      innings.add(InningScore(inning: game.currentInning));
      inningIdx = innings.length - 1;
    }
    innings[inningIdx] = innings[inningIdx].copyWith(
      homeErrors: isHome ? innings[inningIdx].homeErrors + 1 : null,
      awayErrors: !isHome ? innings[inningIdx].awayErrors + 1 : null,
    );
    final updated = game.copyWith(innings: innings);
    await _db.updateGame(updated);
    _activeGame = updated;
    final idx = _games.indexWhere((g) => g.id == updated.id);
    if (idx != -1) _games[idx] = updated;
    notifyListeners();
  }

  Future<void> endGame() async {
    if (_activeGame == null) return;
    final updated = _activeGame!.copyWith(status: GameStatus.completed);
    await _db.updateGame(updated);
    _activeGame = updated;
    final idx = _games.indexWhere((g) => g.id == updated.id);
    if (idx != -1) _games[idx] = updated;
    notifyListeners();
  }

  Future<void> undoLastAtBat() async {
    if (_activeGame == null || _activeAtBats.isEmpty) return;
    await _db.deleteLastAtBat(_activeGame!.id);
    _activeAtBats.removeLast();
    // Reload game from DB for consistency
    _activeGame = await _db.getGame(_activeGame!.id);
    final idx = _games.indexWhere((g) => g.id == _activeGame!.id);
    if (idx != -1) _games[idx] = _activeGame!;
    notifyListeners();
  }

  Future<void> deleteGame(String gameId) async {
    await _db.deleteGame(gameId);
    _games.removeWhere((g) => g.id == gameId);
    if (_activeGame?.id == gameId) _activeGame = null;
    notifyListeners();
  }

  Future<List<AtBat>> getAtBatsForGame(String gameId) async {
    return await _db.getAtBats(gameId);
  }

  Future<List<AtBat>> getAtBatsForPlayer(String playerId) async {
    return await _db.getPlayerAtBats(playerId);
  }

  Future<List<AtBat>> getAtBatsForTeam(String teamId) async {
    return await _db.getTeamAtBats(teamId);
  }
}
