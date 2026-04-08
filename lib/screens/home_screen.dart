import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../providers/team_provider.dart';
import '../models/game.dart';
import '../widgets/ad_banner_widget.dart';
import 'game/new_game_screen.dart';
import 'game/live_scoring_screen.dart';
import 'game/game_history_screen.dart';
import 'teams/teams_screen.dart';
import 'stats/stats_screen.dart';
import 'schedule/schedule_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    _DashboardPage(),
    GameHistoryScreen(),
    TeamsScreen(),
    StatsScreen(),
    ScheduleScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    await Future.wait([
      context.read<GameProvider>().loadGames(),
      context.read<TeamProvider>().loadTeams(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const AdBannerWidget(),
          NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: (i) => setState(() => _currentIndex = i),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.sports_baseball),
                label: 'Accueil',
              ),
              NavigationDestination(
                icon: Icon(Icons.history),
                label: 'Matchs',
              ),
              NavigationDestination(
                icon: Icon(Icons.groups),
                label: 'Équipes',
              ),
              NavigationDestination(
                icon: Icon(Icons.bar_chart),
                label: 'Stats',
              ),
              NavigationDestination(
                icon: Icon(Icons.calendar_month),
                label: 'Calendrier',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DashboardPage extends StatelessWidget {
  const _DashboardPage();

  @override
  Widget build(BuildContext context) {
    final gameProvider = context.watch<GameProvider>();
    final teamProvider = context.watch<TeamProvider>();
    final inProgressGames = gameProvider.inProgressGames;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Baseball Score'),
        centerTitle: true,
        backgroundColor: const Color(0xFF1B2A3B),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Active games section
          if (inProgressGames.isNotEmpty) ...[
            Text(
              'Partie en cours',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
            ),
            const SizedBox(height: 8),
            for (final game in inProgressGames)
              _ActiveGameCard(game: game),
            const SizedBox(height: 16),
          ],

          // Quick actions
          Text(
            'Actions rapides',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.4,
            children: [
              _QuickActionCard(
                icon: Icons.play_circle_filled,
                label: 'Nouvelle partie',
                color: Colors.green,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NewGameScreen()),
                ),
              ),
              _QuickActionCard(
                icon: Icons.history,
                label: 'Historique',
                color: Colors.blue,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const GameHistoryScreen()),
                ),
              ),
              _QuickActionCard(
                icon: Icons.groups,
                label: 'Équipes',
                color: Colors.orange,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TeamsScreen()),
                ),
              ),
              _QuickActionCard(
                icon: Icons.calendar_month,
                label: 'Calendrier',
                color: Colors.purple,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ScheduleScreen()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Stats summary
          _StatsSummaryCard(
            games: gameProvider.completedGames.length,
            teams: teamProvider.teams.length,
          ),
        ],
      ),
    );
  }
}

class _ActiveGameCard extends StatelessWidget {
  final Game game;
  const _ActiveGameCard({required this.game});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF1B2A3B),
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => LiveScoringScreen(gameId: game.id),
          ),
        ),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.circle, color: Colors.green, size: 10),
                  const SizedBox(width: 6),
                  Text(
                    'EN DIRECT — ${game.inningDisplay}',
                    style: const TextStyle(
                      color: Colors.green,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${game.outs} ret.',
                    style: const TextStyle(color: Colors.white54, fontSize: 11),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      game.awayTeamName,
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                  ),
                  Text(
                    '${game.awayScore}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      game.homeTeamName,
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                  ),
                  Text(
                    '${game.homeScore}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                game.location,
                style:
                    const TextStyle(color: Colors.white38, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 36),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatsSummaryCard extends StatelessWidget {
  final int games;
  final int teams;

  const _StatsSummaryCard({required this.games, required this.teams});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Résumé de la saison',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatItem(value: '$games', label: 'Matchs joués'),
                _StatItem(value: '$teams', label: 'Équipes'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;

  const _StatItem({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }
}
