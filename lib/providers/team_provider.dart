import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/team.dart';
import '../models/player.dart';
import '../database/database_helper.dart';

class TeamProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper();
  final _uuid = const Uuid();

  List<Team> _teams = [];
  final Map<String, List<Player>> _playersByTeam = {};
  bool _isLoading = false;

  List<Team> get teams => List.unmodifiable(_teams);
  bool get isLoading => _isLoading;

  List<Player> playersForTeam(String teamId) =>
      List.unmodifiable(_playersByTeam[teamId] ?? []);

  Future<void> loadTeams() async {
    _isLoading = true;
    notifyListeners();

    _teams = await _db.getTeams();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadPlayers(String teamId) async {
    _playersByTeam[teamId] = await _db.getPlayers(teamId);
    notifyListeners();
  }

  Future<Team> addTeam({
    required String name,
    required String city,
    required String logoColor,
  }) async {
    final team = Team(
      id: _uuid.v4(),
      name: name,
      city: city,
      logoColor: logoColor,
      createdAt: DateTime.now(),
    );
    await _db.insertTeam(team);
    _teams.add(team);
    _teams.sort((a, b) => a.fullName.compareTo(b.fullName));
    notifyListeners();
    return team;
  }

  Future<void> updateTeam(Team team) async {
    await _db.updateTeam(team);
    final index = _teams.indexWhere((t) => t.id == team.id);
    if (index != -1) {
      _teams[index] = team;
      notifyListeners();
    }
  }

  Future<void> deleteTeam(String teamId) async {
    await _db.deleteTeam(teamId);
    _teams.removeWhere((t) => t.id == teamId);
    _playersByTeam.remove(teamId);
    notifyListeners();
  }

  Future<Player> addPlayer({
    required String teamId,
    required String name,
    required int number,
    required String position,
  }) async {
    final player = Player(
      id: _uuid.v4(),
      teamId: teamId,
      name: name,
      number: number,
      position: position,
    );
    await _db.insertPlayer(player);
    _playersByTeam[teamId] ??= [];
    _playersByTeam[teamId]!.add(player);
    _playersByTeam[teamId]!.sort((a, b) => a.number.compareTo(b.number));
    notifyListeners();
    return player;
  }

  Future<void> updatePlayer(Player player) async {
    await _db.updatePlayer(player);
    final players = _playersByTeam[player.teamId];
    if (players != null) {
      final index = players.indexWhere((p) => p.id == player.id);
      if (index != -1) {
        players[index] = player;
        players.sort((a, b) => a.number.compareTo(b.number));
        notifyListeners();
      }
    }
  }

  Future<void> deletePlayer(String playerId, String teamId) async {
    await _db.deletePlayer(playerId);
    _playersByTeam[teamId]?.removeWhere((p) => p.id == playerId);
    notifyListeners();
  }

  Team? getTeamById(String id) {
    try {
      return _teams.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  Player? getPlayerById(String id, String teamId) {
    try {
      return _playersByTeam[teamId]?.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }
}
