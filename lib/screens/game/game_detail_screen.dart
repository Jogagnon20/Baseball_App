import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/game_provider.dart';
import '../../providers/team_provider.dart';
import '../../models/game.dart';
import '../../models/at_bat.dart';
import '../../models/player.dart';
import '../../widgets/scoreboard_widget.dart';
import '../../widgets/ad_banner_widget.dart';

class GameDetailScreen extends StatefulWidget {
  final String gameId;
  const GameDetailScreen({super.key, required this.gameId});

  @override
  State<GameDetailScreen> createState() => _GameDetailScreenState();
}

class _GameDetailScreenState extends State<GameDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<AtBat> _atBats = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final gameProvider = context.read<GameProvider>();
    await gameProvider.loadActiveGame(widget.gameId);
    final atBats = await gameProvider.getAtBatsForGame(widget.gameId);
    if (mounted) setState(() => _atBats = atBats);

    // Load team rosters
    final game = gameProvider.activeGame;
    if (game != null) {
      final teamProvider = context.read<TeamProvider>();
      await Future.wait([
        teamProvider.loadPlayers(game.homeTeamId),
        teamProvider.loadPlayers(game.awayTeamId),
      ]);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameProvider>().activeGame;

    if (game == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final dateStr = DateFormat('d MMMM yyyy — HH:mm', 'fr_FR')
        .format(game.gameDate);

    return Scaffold(
      appBar: AppBar(
        title: Text('${game.awayTeamName} @ ${game.homeTeamName}'),
        backgroundColor: const Color(0xFF1B2A3B),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white54,
          indicatorColor: Colors.amber,
          tabs: const [
            Tab(text: 'Résumé'),
            Tab(text: 'Visiteurs'),
            Tab(text: 'Locaux'),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _SummaryTab(game: game, dateStr: dateStr),
                _TeamAtBatTab(
                  game: game,
                  atBats: _atBats.where((ab) => ab.teamId == game.awayTeamId).toList(),
                  teamId: game.awayTeamId,
                  isAway: true,
                ),
                _TeamAtBatTab(
                  game: game,
                  atBats: _atBats.where((ab) => ab.teamId == game.homeTeamId).toList(),
                  teamId: game.homeTeamId,
                  isAway: false,
                ),
              ],
            ),
          ),
          const AdBannerWidget(),
        ],
      ),
    );
  }
}

// ─── Summary tab ─────────────────────────────────────────────────────────────

class _SummaryTab extends StatelessWidget {
  final Game game;
  final String dateStr;

  const _SummaryTab({required this.game, required this.dateStr});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          ScoreboardWidget(game: game),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Final score card
                Card(
                  color: const Color(0xFF1B2A3B),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Text(
                          dateStr,
                          style: const TextStyle(
                              color: Colors.white54, fontSize: 12),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          game.location,
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 12),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _BigScore(
                              teamName: game.awayTeamName,
                              score: game.awayScore,
                              isWinner: game.awayScore > game.homeScore,
                            ),
                            const Text('—',
                                style: TextStyle(
                                    color: Colors.white54, fontSize: 24)),
                            _BigScore(
                              teamName: game.homeTeamName,
                              score: game.homeScore,
                              isWinner: game.homeScore > game.awayScore,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Stats comparison
                Text(
                  'Statistiques de la partie',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                _StatComparison(
                  label: 'Points',
                  away: game.awayScore,
                  home: game.homeScore,
                  awayName: game.awayTeamName,
                  homeName: game.homeTeamName,
                ),
                _StatComparison(
                  label: 'Coups sûrs',
                  away: game.awayHits,
                  home: game.homeHits,
                  awayName: game.awayTeamName,
                  homeName: game.homeTeamName,
                ),
                _StatComparison(
                  label: 'Erreurs',
                  away: game.awayErrors,
                  home: game.homeErrors,
                  awayName: game.awayTeamName,
                  homeName: game.homeTeamName,
                  lowerIsBetter: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BigScore extends StatelessWidget {
  final String teamName;
  final int score;
  final bool isWinner;

  const _BigScore(
      {required this.teamName, required this.score, required this.isWinner});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '$score',
          style: TextStyle(
            color: isWinner ? Colors.amber : Colors.white,
            fontSize: 52,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          teamName,
          style: TextStyle(
            color: isWinner ? Colors.amber : Colors.white70,
            fontSize: 13,
            fontWeight: isWinner ? FontWeight.bold : FontWeight.normal,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _StatComparison extends StatelessWidget {
  final String label;
  final int away;
  final int home;
  final String awayName;
  final String homeName;
  final bool lowerIsBetter;

  const _StatComparison({
    required this.label,
    required this.away,
    required this.home,
    required this.awayName,
    required this.homeName,
    this.lowerIsBetter = false,
  });

  @override
  Widget build(BuildContext context) {
    final awayLeads = lowerIsBetter ? away < home : away > home;
    final homeLeads = lowerIsBetter ? home < away : home > away;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '$away',
              style: TextStyle(
                fontWeight: awayLeads ? FontWeight.bold : FontWeight.normal,
                color: awayLeads ? Colors.green : null,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(label,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ),
          Expanded(
            child: Text(
              '$home',
              style: TextStyle(
                fontWeight: homeLeads ? FontWeight.bold : FontWeight.normal,
                color: homeLeads ? Colors.green : null,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Team at-bat tab ──────────────────────────────────────────────────────────

class _TeamAtBatTab extends StatelessWidget {
  final Game game;
  final List<AtBat> atBats;
  final String teamId;
  final bool isAway;

  const _TeamAtBatTab({
    required this.game,
    required this.atBats,
    required this.teamId,
    required this.isAway,
  });

  @override
  Widget build(BuildContext context) {
    final teamProvider = context.watch<TeamProvider>();
    final players = teamProvider.playersForTeam(teamId);

    if (atBats.isEmpty) {
      return const Center(child: Text('Aucune présence enregistrée'));
    }

    // Group at-bats by inning
    final byInning = <int, List<AtBat>>{};
    for (final ab in atBats) {
      byInning.putIfAbsent(ab.inning, () => []).add(ab);
    }

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        for (final inning in byInning.keys.toList()..sort()) ...[
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            color: const Color(0xFF1B2A3B),
            child: Text(
              '${isAway ? 'Haut' : 'Bas'} ${inning}e manche',
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13),
            ),
          ),
          for (final ab in byInning[inning]!)
            _AtBatTile(
              atBat: ab,
              player: players
                  .where((p) => p.id == ab.playerId)
                  .firstOrNull,
            ),
        ],
      ],
    );
  }
}

class _AtBatTile extends StatelessWidget {
  final AtBat atBat;
  final Player? player;

  const _AtBatTile({required this.atBat, this.player});

  @override
  Widget build(BuildContext context) {
    final resultColor = atBat.result.isHit
        ? Colors.green
        : atBat.result.isOut
            ? Colors.red
            : Colors.blue;

    return ListTile(
      dense: true,
      leading: CircleAvatar(
        backgroundColor: resultColor,
        radius: 16,
        child: Text(
          atBat.result.displayName,
          style: const TextStyle(
              color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
        ),
      ),
      title: Text(
        player != null
            ? '${player!.name} (#${player!.number})'
            : 'Joueur inconnu',
        style: const TextStyle(fontSize: 13),
      ),
      subtitle: Text(
        '${atBat.result.fullName}'
        '${atBat.rbi > 0 ? ' · ${atBat.rbi} RBI' : ''}'
        '${atBat.runsScored > 0 ? ' · ${atBat.runsScored} point(s)' : ''}'
        '${atBat.note != null ? ' · ${atBat.note}' : ''}',
        style: const TextStyle(fontSize: 11),
      ),
      trailing: Text(
        '${atBat.balls}-${atBat.strikes}',
        style: const TextStyle(color: Colors.grey, fontSize: 11),
      ),
    );
  }
}
