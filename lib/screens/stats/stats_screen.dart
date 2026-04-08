import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/stats_provider.dart';
import '../../models/player_stats.dart';
import '../../widgets/ad_banner_widget.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StatsProvider>().computeStats();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistiques'),
        backgroundColor: const Color(0xFF1B2A3B),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<StatsProvider>().computeStats(),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white54,
          indicatorColor: Colors.amber,
          tabs: const [
            Tab(text: 'Classement'),
            Tab(text: 'Frappeurs'),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                _TeamStandingsTab(),
                _PlayerStatsTab(),
              ],
            ),
          ),
          const AdBannerWidget(),
        ],
      ),
    );
  }
}

// ─── Team standings ───────────────────────────────────────────────────────────

class _TeamStandingsTab extends StatelessWidget {
  const _TeamStandingsTab();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StatsProvider>();

    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.teamStats.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bar_chart, size: 64, color: Colors.grey),
            SizedBox(height: 12),
            Text('Aucune statistique disponible'),
            SizedBox(height: 4),
            Text(
              'Terminez des parties pour voir les stats',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        // Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF1B2A3B),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Row(
            children: [
              Expanded(
                flex: 3,
                child: Text('Équipe',
                    style: TextStyle(
                        color: Colors.white54,
                        fontSize: 11,
                        fontWeight: FontWeight.bold)),
              ),
              _HeaderCell('PJ'),
              _HeaderCell('V'),
              _HeaderCell('D'),
              _HeaderCell('PCT'),
              _HeaderCell('R+'),
              _HeaderCell('R-'),
              _HeaderCell('DF'),
            ],
          ),
        ),
        const SizedBox(height: 4),
        for (int i = 0; i < provider.teamStats.length; i++)
          _TeamStandingRow(
            stats: provider.teamStats[i],
            rank: i + 1,
          ),
      ],
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final String text;
  const _HeaderCell(this.text);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 36,
      child: Text(
        text,
        style: const TextStyle(
            color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _TeamStandingRow extends StatelessWidget {
  final TeamStats stats;
  final int rank;

  const _TeamStandingRow({required this.stats, required this.rank});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 2),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            SizedBox(
              width: 20,
              child: Text(
                '$rank',
                style: const TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                    fontSize: 12),
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(
                stats.teamName,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 13),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            _DataCell('${stats.gamesPlayed}'),
            _DataCell('${stats.wins}', color: Colors.green),
            _DataCell('${stats.losses}', color: Colors.red),
            _DataCell(stats.winPctDisplay),
            _DataCell('${stats.runsScored}'),
            _DataCell('${stats.runsAllowed}'),
            _DataCell(
              '${stats.runDifferential >= 0 ? '+' : ''}${stats.runDifferential}',
              color: stats.runDifferential >= 0 ? Colors.green : Colors.red,
            ),
          ],
        ),
      ),
    );
  }
}

class _DataCell extends StatelessWidget {
  final String text;
  final Color? color;
  const _DataCell(this.text, {this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 36,
      child: Text(
        text,
        style: TextStyle(
            color: color, fontSize: 12, fontWeight: FontWeight.w500),
        textAlign: TextAlign.center,
      ),
    );
  }
}

// ─── Player stats ─────────────────────────────────────────────────────────────

class _PlayerStatsTab extends StatelessWidget {
  const _PlayerStatsTab();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StatsProvider>();

    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final stats = provider.playerStats
        .where((s) => s.atBats >= 1)
        .toList();

    if (stats.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person, size: 64, color: Colors.grey),
            SizedBox(height: 12),
            Text('Aucune statistique de frappeur'),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        // Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF1B2A3B),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Row(
            children: [
              Expanded(
                flex: 3,
                child: Text('Joueur',
                    style: TextStyle(
                        color: Colors.white54,
                        fontSize: 11,
                        fontWeight: FontWeight.bold)),
              ),
              _HeaderCell('PA'),
              _HeaderCell('AB'),
              _HeaderCell('H'),
              _HeaderCell('HR'),
              _HeaderCell('RBI'),
              _HeaderCell('AVG'),
              _HeaderCell('OBP'),
            ],
          ),
        ),
        const SizedBox(height: 4),
        for (int i = 0; i < stats.length; i++)
          _PlayerStatsRow(stats: stats[i], rank: i + 1),
      ],
    );
  }
}

class _PlayerStatsRow extends StatelessWidget {
  final PlayerStats stats;
  final int rank;

  const _PlayerStatsRow({required this.stats, required this.rank});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 2),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            SizedBox(
              width: 20,
              child: Text(
                '$rank',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ),
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stats.playerName,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    stats.teamName,
                    style: const TextStyle(
                        color: Colors.grey, fontSize: 10),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            _DataCell('${stats.atBats + stats.walks + stats.hitByPitch + stats.sacrifices}'),
            _DataCell('${stats.atBats}'),
            _DataCell('${stats.hits}'),
            _DataCell('${stats.homeRuns}',
                color: stats.homeRuns > 0 ? Colors.amber : null),
            _DataCell('${stats.rbi}'),
            _DataCell(stats.avgDisplay,
                color: stats.battingAverage >= 0.300 ? Colors.green : null),
            _DataCell(stats.obpDisplay),
          ],
        ),
      ),
    );
  }
}
