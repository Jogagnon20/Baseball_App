import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/game_provider.dart';
import '../../models/game.dart';
import 'game_detail_screen.dart';
import 'live_scoring_screen.dart';

class GameHistoryScreen extends StatelessWidget {
  const GameHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final gameProvider = context.watch<GameProvider>();
    final games = gameProvider.games;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historique des matchs'),
        backgroundColor: const Color(0xFF1B2A3B),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: gameProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : games.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.sports_baseball,
                                size: 64, color: Colors.grey),
                            SizedBox(height: 12),
                            Text('Aucun match enregistré'),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: games.length,
                        itemBuilder: (_, i) => _GameCard(game: games[i]),
                      ),
          ),
        ],
      ),
    );
  }
}

class _GameCard extends StatelessWidget {
  final Game game;
  const _GameCard({required this.game});

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('d MMM yyyy — HH:mm', 'fr_FR')
        .format(game.gameDate);
    final isInProgress = game.status == GameStatus.inProgress;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => isInProgress
                ? LiveScoringScreen(gameId: game.id)
                : GameDetailScreen(gameId: game.id),
          ),
        ),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _StatusChip(status: game.status),
                  const Spacer(),
                  Text(
                    dateStr,
                    style: const TextStyle(
                        color: Colors.grey, fontSize: 11),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _TeamScoreLine(
                          name: game.awayTeamName,
                          score: game.awayScore,
                          isWinner: game.status == GameStatus.completed &&
                              game.awayScore > game.homeScore,
                        ),
                        const SizedBox(height: 4),
                        _TeamScoreLine(
                          name: game.homeTeamName,
                          score: game.homeScore,
                          isWinner: game.status == GameStatus.completed &&
                              game.homeScore > game.awayScore,
                        ),
                      ],
                    ),
                  ),
                  if (isInProgress)
                    const Icon(Icons.play_circle_fill,
                        color: Colors.green, size: 28),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.location_on,
                      size: 12, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      game.location,
                      style: const TextStyle(
                          color: Colors.grey, fontSize: 11),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (v) {
                      if (v == 'delete') {
                        _confirmDelete(context);
                      }
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Supprimer',
                            style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Supprimer le match'),
        content: Text(
            'Supprimer ${game.awayTeamName} @ ${game.homeTeamName} ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              context.read<GameProvider>().deleteGame(game.id);
              Navigator.pop(context);
            },
            child: const Text('Supprimer',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _TeamScoreLine extends StatelessWidget {
  final String name;
  final int score;
  final bool isWinner;

  const _TeamScoreLine({
    required this.name,
    required this.score,
    required this.isWinner,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (isWinner)
          const Icon(Icons.arrow_right, color: Colors.green, size: 18)
        else
          const SizedBox(width: 18),
        Expanded(
          child: Text(
            name,
            style: TextStyle(
              fontWeight: isWinner ? FontWeight.bold : FontWeight.normal,
              fontSize: 14,
            ),
          ),
        ),
        Text(
          '$score',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: isWinner ? Colors.green : null,
          ),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  final GameStatus status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      GameStatus.inProgress => ('EN COURS', Colors.green),
      GameStatus.completed => ('TERMINÉ', Colors.blueGrey),
      GameStatus.cancelled => ('ANNULÉ', Colors.red),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(100)),
      ),
      child: Text(
        label,
        style:
            TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}
