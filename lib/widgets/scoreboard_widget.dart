import 'package:flutter/material.dart';
import '../models/game.dart';

class ScoreboardWidget extends StatelessWidget {
  final Game game;

  const ScoreboardWidget({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxInning = game.totalInnings > game.currentInning
        ? game.totalInnings
        : game.currentInning;

    return Container(
      color: const Color(0xFF1B2A3B),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header row: inning numbers
          Row(
            children: [
              SizedBox(
                width: 80,
                child: Text(
                  'Équipe',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white70,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (int i = 1; i <= maxInning; i++)
                        _InningCell(
                          text: '$i',
                          isHeader: true,
                          isCurrent: i == game.currentInning &&
                              game.status == GameStatus.inProgress,
                        ),
                      const _InningCell(text: 'R', isHeader: true, isCurrent: false),
                      const _InningCell(text: 'H', isHeader: true, isCurrent: false),
                      const _InningCell(text: 'E', isHeader: true, isCurrent: false),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const Divider(color: Colors.white24, height: 4),
          // Away team row
          _TeamScoreRow(
            teamName: game.awayTeamName,
            innings: game.innings,
            isAway: true,
            maxInning: maxInning,
            totalRuns: game.awayScore,
            totalHits: game.awayHits,
            totalErrors: game.awayErrors,
            currentInning: game.currentInning,
            gameStatus: game.status,
          ),
          const SizedBox(height: 2),
          // Home team row
          _TeamScoreRow(
            teamName: game.homeTeamName,
            innings: game.innings,
            isAway: false,
            maxInning: maxInning,
            totalRuns: game.homeScore,
            totalHits: game.homeHits,
            totalErrors: game.homeErrors,
            currentInning: game.currentInning,
            gameStatus: game.status,
          ),
        ],
      ),
    );
  }
}

class _TeamScoreRow extends StatelessWidget {
  final String teamName;
  final List<InningScore> innings;
  final bool isAway;
  final int maxInning;
  final int totalRuns;
  final int totalHits;
  final int totalErrors;
  final int currentInning;
  final GameStatus gameStatus;

  const _TeamScoreRow({
    required this.teamName,
    required this.innings,
    required this.isAway,
    required this.maxInning,
    required this.totalRuns,
    required this.totalHits,
    required this.totalErrors,
    required this.currentInning,
    required this.gameStatus,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(
            teamName,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (int i = 1; i <= maxInning; i++)
                  _buildInningScore(i),
                _InningCell(
                  text: '$totalRuns',
                  isHeader: false,
                  isCurrent: false,
                  isBold: true,
                  color: Colors.amber,
                ),
                _InningCell(
                  text: '$totalHits',
                  isHeader: false,
                  isCurrent: false,
                ),
                _InningCell(
                  text: '$totalErrors',
                  isHeader: false,
                  isCurrent: false,
                  color: totalErrors > 0 ? Colors.redAccent : null,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInningScore(int inning) {
    final score = innings.where((i) => i.inning == inning).firstOrNull;
    final runs = score == null
        ? null
        : isAway ? score.awayRuns : score.homeRuns;
    final isCurrent = inning == currentInning && gameStatus == GameStatus.inProgress;
    return _InningCell(
      text: runs == null ? '-' : '$runs',
      isHeader: false,
      isCurrent: isCurrent,
    );
  }
}

class _InningCell extends StatelessWidget {
  final String text;
  final bool isHeader;
  final bool isCurrent;
  final bool isBold;
  final Color? color;

  const _InningCell({
    required this.text,
    required this.isHeader,
    required this.isCurrent,
    this.isBold = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 24,
      margin: const EdgeInsets.symmetric(horizontal: 1),
      decoration: isCurrent
          ? BoxDecoration(
              color: Colors.blue.withAlpha(80),
              borderRadius: BorderRadius.circular(3),
            )
          : null,
      alignment: Alignment.center,
      child: Text(
        text,
        style: TextStyle(
          color: color ?? (isHeader ? Colors.white54 : Colors.white),
          fontSize: 12,
          fontWeight: (isHeader || isBold) ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}
