import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/player.dart';
import '../models/team.dart';
import '../models/game.dart';
import '../models/at_bat.dart';
import '../models/schedule_event.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'baseball_app.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDb,
    );
  }

  Future<void> _createDb(Database db, int version) async {
    await db.execute('''
      CREATE TABLE teams (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        city TEXT NOT NULL,
        logoColor TEXT NOT NULL,
        createdAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE players (
        id TEXT PRIMARY KEY,
        teamId TEXT NOT NULL,
        name TEXT NOT NULL,
        number INTEGER NOT NULL,
        position TEXT NOT NULL,
        isActive INTEGER NOT NULL DEFAULT 1,
        FOREIGN KEY (teamId) REFERENCES teams(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE games (
        id TEXT PRIMARY KEY,
        homeTeamId TEXT NOT NULL,
        awayTeamId TEXT NOT NULL,
        homeTeamName TEXT NOT NULL,
        awayTeamName TEXT NOT NULL,
        gameDate TEXT NOT NULL,
        location TEXT NOT NULL,
        status INTEGER NOT NULL DEFAULT 0,
        currentInning INTEGER NOT NULL DEFAULT 1,
        isTopInning INTEGER NOT NULL DEFAULT 1,
        outs INTEGER NOT NULL DEFAULT 0,
        innings TEXT NOT NULL DEFAULT '[]',
        homeLineup TEXT NOT NULL DEFAULT '[]',
        awayLineup TEXT NOT NULL DEFAULT '[]',
        currentHomeBatter INTEGER NOT NULL DEFAULT 0,
        currentAwayBatter INTEGER NOT NULL DEFAULT 0,
        runner1st INTEGER NOT NULL DEFAULT 0,
        runner2nd INTEGER NOT NULL DEFAULT 0,
        runner3rd INTEGER NOT NULL DEFAULT 0,
        notes TEXT,
        totalInnings INTEGER NOT NULL DEFAULT 9
      )
    ''');

    await db.execute('''
      CREATE TABLE at_bats (
        id TEXT PRIMARY KEY,
        gameId TEXT NOT NULL,
        playerId TEXT NOT NULL,
        teamId TEXT NOT NULL,
        inning INTEGER NOT NULL,
        isTopInning INTEGER NOT NULL,
        batterOrder INTEGER NOT NULL,
        result INTEGER NOT NULL,
        rbi INTEGER NOT NULL DEFAULT 0,
        runsScored INTEGER NOT NULL DEFAULT 0,
        balls INTEGER NOT NULL DEFAULT 0,
        strikes INTEGER NOT NULL DEFAULT 0,
        note TEXT,
        timestamp TEXT NOT NULL,
        FOREIGN KEY (gameId) REFERENCES games(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE schedule_events (
        id TEXT PRIMARY KEY,
        homeTeamId TEXT NOT NULL,
        awayTeamId TEXT NOT NULL,
        homeTeamName TEXT NOT NULL,
        awayTeamName TEXT NOT NULL,
        dateTime TEXT NOT NULL,
        location TEXT NOT NULL,
        notes TEXT,
        linkedGameId TEXT
      )
    ''');
  }

  // ─── TEAMS ───────────────────────────────────────────────────────────────

  Future<String> insertTeam(Team team) async {
    final db = await database;
    await db.insert('teams', team.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
    return team.id;
  }

  Future<List<Team>> getTeams() async {
    final db = await database;
    final maps = await db.query('teams', orderBy: 'city ASC, name ASC');
    return maps.map((m) => Team.fromMap(m)).toList();
  }

  Future<Team?> getTeam(String id) async {
    final db = await database;
    final maps = await db.query('teams', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Team.fromMap(maps.first);
  }

  Future<void> updateTeam(Team team) async {
    final db = await database;
    await db.update('teams', team.toMap(),
        where: 'id = ?', whereArgs: [team.id]);
  }

  Future<void> deleteTeam(String id) async {
    final db = await database;
    await db.delete('teams', where: 'id = ?', whereArgs: [id]);
    await db.delete('players', where: 'teamId = ?', whereArgs: [id]);
  }

  // ─── PLAYERS ─────────────────────────────────────────────────────────────

  Future<String> insertPlayer(Player player) async {
    final db = await database;
    await db.insert('players', player.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
    return player.id;
  }

  Future<List<Player>> getPlayers(String teamId) async {
    final db = await database;
    final maps = await db.query(
      'players',
      where: 'teamId = ?',
      whereArgs: [teamId],
      orderBy: 'number ASC',
    );
    return maps.map((m) => Player.fromMap(m)).toList();
  }

  Future<Player?> getPlayer(String id) async {
    final db = await database;
    final maps = await db.query('players', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Player.fromMap(maps.first);
  }

  Future<void> updatePlayer(Player player) async {
    final db = await database;
    await db.update('players', player.toMap(),
        where: 'id = ?', whereArgs: [player.id]);
  }

  Future<void> deletePlayer(String id) async {
    final db = await database;
    await db.delete('players', where: 'id = ?', whereArgs: [id]);
  }

  // ─── GAMES ───────────────────────────────────────────────────────────────

  Future<String> insertGame(Game game) async {
    final db = await database;
    await db.insert('games', game.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
    return game.id;
  }

  Future<List<Game>> getGames({GameStatus? status}) async {
    final db = await database;
    final maps = await db.query(
      'games',
      where: status != null ? 'status = ?' : null,
      whereArgs: status != null ? [status.index] : null,
      orderBy: 'gameDate DESC',
    );
    return maps.map((m) => Game.fromMap(m)).toList();
  }

  Future<Game?> getGame(String id) async {
    final db = await database;
    final maps = await db.query('games', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Game.fromMap(maps.first);
  }

  Future<void> updateGame(Game game) async {
    final db = await database;
    await db.update('games', game.toMap(),
        where: 'id = ?', whereArgs: [game.id]);
  }

  Future<void> deleteGame(String id) async {
    final db = await database;
    await db.delete('games', where: 'id = ?', whereArgs: [id]);
    await db.delete('at_bats', where: 'gameId = ?', whereArgs: [id]);
  }

  // ─── AT BATS ─────────────────────────────────────────────────────────────

  Future<String> insertAtBat(AtBat atBat) async {
    final db = await database;
    await db.insert('at_bats', atBat.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
    return atBat.id;
  }

  Future<List<AtBat>> getAtBats(String gameId) async {
    final db = await database;
    final maps = await db.query(
      'at_bats',
      where: 'gameId = ?',
      whereArgs: [gameId],
      orderBy: 'timestamp ASC',
    );
    return maps.map((m) => AtBat.fromMap(m)).toList();
  }

  Future<List<AtBat>> getPlayerAtBats(String playerId) async {
    final db = await database;
    final maps = await db.query(
      'at_bats',
      where: 'playerId = ?',
      whereArgs: [playerId],
      orderBy: 'timestamp ASC',
    );
    return maps.map((m) => AtBat.fromMap(m)).toList();
  }

  Future<List<AtBat>> getTeamAtBats(String teamId) async {
    final db = await database;
    final maps = await db.query(
      'at_bats',
      where: 'teamId = ?',
      whereArgs: [teamId],
    );
    return maps.map((m) => AtBat.fromMap(m)).toList();
  }

  Future<void> deleteLastAtBat(String gameId) async {
    final db = await database;
    final maps = await db.query(
      'at_bats',
      where: 'gameId = ?',
      whereArgs: [gameId],
      orderBy: 'timestamp DESC',
      limit: 1,
    );
    if (maps.isNotEmpty) {
      await db.delete('at_bats',
          where: 'id = ?', whereArgs: [maps.first['id']]);
    }
  }

  // ─── SCHEDULE EVENTS ─────────────────────────────────────────────────────

  Future<String> insertScheduleEvent(ScheduleEvent event) async {
    final db = await database;
    await db.insert('schedule_events', event.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
    return event.id;
  }

  Future<List<ScheduleEvent>> getScheduleEvents() async {
    final db = await database;
    final maps = await db.query('schedule_events', orderBy: 'dateTime ASC');
    return maps.map((m) => ScheduleEvent.fromMap(m)).toList();
  }

  Future<void> updateScheduleEvent(ScheduleEvent event) async {
    final db = await database;
    await db.update('schedule_events', event.toMap(),
        where: 'id = ?', whereArgs: [event.id]);
  }

  Future<void> deleteScheduleEvent(String id) async {
    final db = await database;
    await db.delete('schedule_events', where: 'id = ?', whereArgs: [id]);
  }
}
