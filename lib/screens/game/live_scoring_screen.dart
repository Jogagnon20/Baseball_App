import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/game_provider.dart';
import '../../providers/team_provider.dart';
import '../../models/game.dart';
import '../../models/at_bat.dart';
import '../../models/player.dart';
import '../../widgets/scoreboard_widget.dart';
import '../../widgets/base_diamond_widget.dart';
import '../../widgets/ad_banner_widget.dart';
import 'game_detail_screen.dart';

class LiveScoringScreen extends StatefulWidget {
  final String gameId;
  const LiveScoringScreen({super.key, required this.gameId});

  @override
  State<LiveScoringScreen> createState() => _LiveScoringScreenState();
}

class _LiveScoringScreenState extends State<LiveScoringScreen> {
  int _balls = 0;
  int _strikes = 0;
  int _rbi = 0;
  int _runsScored = 0;
  final _noteCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GameProvider>().loadActiveGame(widget.gameId);
    });
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  void _reset() {
    setState(() {
      _balls = 0;
      _strikes = 0;
      _rbi = 0;
      _runsScored = 0;
      _noteCtrl.clear();
    });
  }

  // ── Prévisualisation auto-calcul selon le résultat ─────────────────────────

  int _calcAutoRuns(Game game) {
    final r1 = game.runner1st;
    final r2 = game.runner2nd;
    final r3 = game.runner3rd;
    // Affiche combien de points seraient marqués dans les cas les plus courants
    if (r3) return 1; // au moins 1 si coureur au 3e
    if (r2) return 0;
    return 0;
  }

  int _calcAutoRbi(Game game) => _rbi; // le provider gère le calcul final

  @override
  Widget build(BuildContext context) {
    final gameProvider = context.watch<GameProvider>();
    final teamProvider = context.watch<TeamProvider>();
    final game = gameProvider.activeGame;

    if (game == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (game.status == GameStatus.completed) {
      return GameDetailScreen(gameId: game.id);
    }

    final currentTeamId = game.currentTeamId;
    final currentLineup = game.currentLineup;
    final currentBatterIndex = game.currentBatterIndex;

    // Get current batter
    Player? currentBatter;
    if (currentLineup.isNotEmpty) {
      final batterId = currentLineup[currentBatterIndex % currentLineup.length];
      currentBatter = teamProvider.getPlayerById(batterId, currentTeamId);
    }

    final teamName = game.isTopInning ? game.awayTeamName : game.homeTeamName;

    return Scaffold(
      appBar: AppBar(
        title: Text('${game.awayTeamName} @ ${game.homeTeamName}'),
        backgroundColor: const Color(0xFF1B2A3B),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.undo),
            tooltip: 'Annuler dernière action',
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Annuler'),
                  content: const Text(
                      'Annuler la dernière présence au bâton ?'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Non')),
                    TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Oui')),
                  ],
                ),
              );
              if (confirmed == true && mounted) {
                await context.read<GameProvider>().undoLastAtBat();
                _reset();
              }
            },
          ),
          PopupMenuButton<String>(
            onSelected: (v) => _handleMenu(context, v),
            itemBuilder: (_) => [
              const PopupMenuItem(
                  value: 'error_home', child: Text('Erreur — Local')),
              const PopupMenuItem(
                  value: 'error_away', child: Text('Erreur — Visiteur')),
              const PopupMenuItem(
                  value: 'end', child: Text('Terminer la partie')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Scoreboard
          ScoreboardWidget(game: game),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  // Current situation
                  _SituationCard(
                    game: game,
                    teamName: teamName,
                    currentBatter: currentBatter,
                    batterIndex: currentBatterIndex,
                  ),
                  const SizedBox(height: 12),

                  // Count & runners
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Base diamond
                      Expanded(
                        child: Card(
                          color: const Color(0xFF1B2A3B),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              children: [
                                BaseDiamondWidget(
                                  runner1st: game.runner1st,
                                  runner2nd: game.runner2nd,
                                  runner3rd: game.runner3rd,
                                  outs: game.outs,
                                  size: 110,
                                ),
                                const SizedBox(height: 8),
                                // Runner toggles
                                _RunnerToggles(game: game),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Count
                      Expanded(
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              children: [
                                _CountRow(
                                  label: 'Balles',
                                  count: _balls,
                                  max: 4,
                                  color: Colors.green,
                                  onTap: () => setState(
                                      () => _balls = (_balls + 1) % 5),
                                ),
                                const SizedBox(height: 8),
                                _CountRow(
                                  label: 'Prises',
                                  count: _strikes,
                                  max: 3,
                                  color: Colors.red,
                                  onTap: () => setState(
                                      () => _strikes = (_strikes + 1) % 4),
                                ),
                                const Divider(),
                                _AutoCountRow(
                                  label: 'RBI',
                                  manualCount: _rbi,
                                  autoCount: _calcAutoRbi(game),
                                  max: 7,
                                  color: Colors.amber,
                                  onTap: () =>
                                      setState(() => _rbi = (_rbi + 1) % 8),
                                  onReset: () => setState(() => _rbi = 0),
                                ),
                                const SizedBox(height: 4),
                                _AutoCountRow(
                                  label: 'Points marqués',
                                  manualCount: _runsScored,
                                  autoCount: _calcAutoRuns(game),
                                  max: 7,
                                  color: Colors.orange,
                                  onTap: () => setState(
                                      () => _runsScored = (_runsScored + 1) % 8),
                                  onReset: () => setState(() => _runsScored = 0),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Result buttons
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Résultat de la présence',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 10),
                          _ResultButtons(
                            onResult: (result) =>
                                _recordAtBat(context, result, game),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),
                  // Optional note
                  TextField(
                    controller: _noteCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Note (optionnel)',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    maxLines: 1,
                  ),
                  const SizedBox(height: 60),
                ],
              ),
            ),
          ),
          const AdBannerWidget(),
        ],
      ),
    );
  }

  Future<void> _recordAtBat(
      BuildContext context, AtBatResult result, Game game) async {
    final provider = context.read<GameProvider>();
    final teamProvider = context.read<TeamProvider>();

    final currentLineup = game.currentLineup;
    if (currentLineup.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aucun joueur dans l\'alignement')),
      );
      return;
    }

    final batterId =
        currentLineup[game.currentBatterIndex % currentLineup.length];

    await provider.recordAtBat(
      playerId: batterId,
      teamId: game.currentTeamId,
      result: result,
      balls: _balls,
      strikes: _strikes,
      rbi: _rbi,
      runsScored: _runsScored,
      note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
    );

    _reset();

    // Check if game is over
    final updatedGame = provider.activeGame;
    if (updatedGame != null &&
        updatedGame.currentInning > updatedGame.totalInnings &&
        updatedGame.homeScore != updatedGame.awayScore) {
      if (mounted) {
        _showEndGameDialog(context);
      }
    }
  }

  void _showEndGameDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Fin de partie?'),
        content: const Text(
            'Toutes les manches sont terminées. Voulez-vous conclure la partie?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Continuer'),
          ),
          ElevatedButton(
            onPressed: () async {
              await context.read<GameProvider>().endGame();
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Terminer'),
          ),
        ],
      ),
    );
  }

  void _handleMenu(BuildContext context, String action) async {
    switch (action) {
      case 'error_home':
        await context.read<GameProvider>().addError(isHome: true);
      case 'error_away':
        await context.read<GameProvider>().addError(isHome: false);
      case 'end':
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Terminer la partie'),
            content: const Text(
                'Êtes-vous sûr de vouloir terminer la partie maintenant?'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Annuler')),
              ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text('Terminer',
                      style: TextStyle(color: Colors.white))),
            ],
          ),
        );
        if (confirmed == true && mounted) {
          await context.read<GameProvider>().endGame();
        }
    }
  }
}

// ─── Situation card ──────────────────────────────────────────────────────────

class _SituationCard extends StatelessWidget {
  final Game game;
  final String teamName;
  final Player? currentBatter;
  final int batterIndex;

  const _SituationCard({
    required this.game,
    required this.teamName,
    required this.currentBatter,
    required this.batterIndex,
  });

  @override
  Widget build(BuildContext context) {
    final half = game.isTopInning ? 'Haut' : 'Bas';
    return Card(
      color: const Color(0xFF1B2A3B),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$half de la ${game.currentInning}e manche',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    teamName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (currentBatter != null)
                    Text(
                      '#${batterIndex + 1} — ${currentBatter!.name} (#${currentBatter!.number}) ${currentBatter!.position}',
                      style: const TextStyle(
                        color: Colors.amber,
                        fontSize: 13,
                      ),
                    )
                  else
                    const Text(
                      'Aucun frappeur',
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                ],
              ),
            ),
            Column(
              children: [
                Text(
                  '${game.awayScore}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${game.homeScore}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Runner toggles ───────────────────────────────────────────────────────────

class _RunnerToggles extends StatelessWidget {
  final Game game;
  const _RunnerToggles({required this.game});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _BaseToggle(
          label: '3B',
          active: game.runner3rd,
          onTap: () => context.read<GameProvider>().updateRunners(
              r1: game.runner1st,
              r2: game.runner2nd,
              r3: !game.runner3rd),
        ),
        const SizedBox(width: 6),
        _BaseToggle(
          label: '2B',
          active: game.runner2nd,
          onTap: () => context.read<GameProvider>().updateRunners(
              r1: game.runner1st,
              r2: !game.runner2nd,
              r3: game.runner3rd),
        ),
        const SizedBox(width: 6),
        _BaseToggle(
          label: '1B',
          active: game.runner1st,
          onTap: () => context.read<GameProvider>().updateRunners(
              r1: !game.runner1st,
              r2: game.runner2nd,
              r3: game.runner3rd),
        ),
      ],
    );
  }
}

class _BaseToggle extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _BaseToggle(
      {required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: active ? Colors.amber : Colors.transparent,
          border: Border.all(
            color: active ? Colors.amber : Colors.white38,
          ),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.black : Colors.white54,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

// ─── Count row ───────────────────────────────────────────────────────────────

class _CountRow extends StatelessWidget {
  final String label;
  final int count;
  final int max;
  final Color color;
  final VoidCallback onTap;

  const _CountRow({
    required this.label,
    required this.count,
    required this.max,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 11),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Row(
            children: List.generate(max, (i) {
              return Container(
                width: 14,
                height: 14,
                margin: const EdgeInsets.symmetric(horizontal: 1),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i < count ? color : Colors.transparent,
                  border: Border.all(
                    color: i < count ? color : Colors.grey.shade400,
                    width: 1.5,
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

// ─── Result buttons ───────────────────────────────────────────────────────────

class _ResultButtons extends StatelessWidget {
  final ValueChanged<AtBatResult> onResult;
  const _ResultButtons({required this.onResult});

  @override
  Widget build(BuildContext context) {
    final groups = [
      {
        'label': 'Coups sûrs',
        'color': Colors.green,
        'results': [
          AtBatResult.single,
          AtBatResult.double_,
          AtBatResult.triple,
          AtBatResult.homeRun,
        ],
      },
      {
        'label': 'Retraits',
        'color': Colors.red,
        'results': [
          AtBatResult.strikeoutS,
          AtBatResult.strikeoutL,
          AtBatResult.groundOut,
          AtBatResult.flyOut,
          AtBatResult.lineOut,
          AtBatResult.doublePlay,
        ],
      },
      {
        'label': 'Sur les buts (sans retrait)',
        'color': Colors.blue,
        'results': [
          AtBatResult.walk,
          AtBatResult.hitByPitch,
          AtBatResult.intentionalWalk,
          AtBatResult.fieldersChoice,
          AtBatResult.error,
          AtBatResult.sacrifice,
        ],
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final group in groups) ...[
          Text(
            group['label'] as String,
            style: TextStyle(
              fontSize: 11,
              color: (group['color'] as Color).withAlpha(200),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: (group['results'] as List<AtBatResult>).map((r) {
              return ElevatedButton(
                onPressed: () => onResult(r),
                style: ElevatedButton.styleFrom(
                  backgroundColor: group['color'] as Color,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  minimumSize: const Size(0, 32),
                  textStyle: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.bold),
                ),
                child: Text(r.displayName),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

// ─── Compteur avec valeur auto affichée ──────────────────────────────────────

/// Compteur qui affiche "AUTO" quand la valeur est 0 (le provider calculera
/// automatiquement). Permet l'override manuel en tapant pour incrémenter.
/// Appui long remet à 0 (retour en mode auto).
class _AutoCountRow extends StatelessWidget {
  final String label;
  final int manualCount;
  final int autoCount;
  final int max;
  final Color color;
  final VoidCallback onTap;
  final VoidCallback onReset;

  const _AutoCountRow({
    required this.label,
    required this.manualCount,
    required this.autoCount,
    required this.max,
    required this.color,
    required this.onTap,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    final isAuto = manualCount == 0;
    final displayCount = manualCount;

    return GestureDetector(
      onTap: onTap,
      onLongPress: onReset,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 11)),
                if (isAuto)
                  Text(
                    'auto • appui long = reset',
                    style: TextStyle(
                        fontSize: 9,
                        color: color.withAlpha(180),
                        fontStyle: FontStyle.italic),
                  ),
              ],
            ),
          ),
          if (isAuto)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: color.withAlpha(30),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: color.withAlpha(100)),
              ),
              child: Text(
                'AUTO',
                style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.bold),
              ),
            )
          else
            Row(
              children: List.generate(max, (i) {
                return Container(
                  width: 14,
                  height: 14,
                  margin: const EdgeInsets.symmetric(horizontal: 1),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i < displayCount ? color : Colors.transparent,
                    border: Border.all(
                      color: i < displayCount ? color : Colors.grey.shade400,
                      width: 1.5,
                    ),
                  ),
                );
              }),
            ),
        ],
      ),
    );
  }
}
