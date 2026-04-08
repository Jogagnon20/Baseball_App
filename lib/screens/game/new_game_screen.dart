import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/game_provider.dart';
import '../../providers/team_provider.dart';
import '../../models/team.dart';
import '../../models/player.dart';
import 'live_scoring_screen.dart';

class NewGameScreen extends StatefulWidget {
  const NewGameScreen({super.key});

  @override
  State<NewGameScreen> createState() => _NewGameScreenState();
}

class _NewGameScreenState extends State<NewGameScreen> {
  final _formKey = GlobalKey<FormState>();
  final _locationCtrl = TextEditingController();

  Team? _homeTeam;
  Team? _awayTeam;
  DateTime _gameDate = DateTime.now();
  TimeOfDay _gameTime = TimeOfDay.now();
  int _totalInnings = 9;

  List<Player> _homePlayers = [];
  List<Player> _awayPlayers = [];
  List<String> _homeLineup = [];
  List<String> _awayLineup = [];

  bool _isCreating = false;

  @override
  void dispose() {
    _locationCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final teamProvider = context.watch<TeamProvider>();
    final teams = teamProvider.teams;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nouvelle partie'),
        backgroundColor: const Color(0xFF1B2A3B),
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Teams selection
            _SectionTitle(title: 'Équipes'),
            Row(
              children: [
                Expanded(
                  child: _TeamDropdown(
                    label: 'Visiteurs',
                    teams: teams,
                    selected: _awayTeam,
                    excluded: _homeTeam?.id,
                    onChanged: (team) {
                      setState(() {
                        _awayTeam = team;
                        _awayPlayers = [];
                        _awayLineup = [];
                      });
                      if (team != null) _loadPlayers(team, isHome: false);
                    },
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text('@', style: TextStyle(fontSize: 20)),
                ),
                Expanded(
                  child: _TeamDropdown(
                    label: 'Locaux',
                    teams: teams,
                    selected: _homeTeam,
                    excluded: _awayTeam?.id,
                    onChanged: (team) {
                      setState(() {
                        _homeTeam = team;
                        _homePlayers = [];
                        _homeLineup = [];
                      });
                      if (team != null) _loadPlayers(team, isHome: true);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Lineups
            if (_awayTeam != null && _awayPlayers.isNotEmpty) ...[
              _SectionTitle(title: 'Alignement — ${_awayTeam!.name} (Visiteurs)'),
              _LineupBuilder(
                players: _awayPlayers,
                lineup: _awayLineup,
                onChanged: (lineup) => setState(() => _awayLineup = lineup),
              ),
              const SizedBox(height: 12),
            ],
            if (_homeTeam != null && _homePlayers.isNotEmpty) ...[
              _SectionTitle(title: 'Alignement — ${_homeTeam!.name} (Locaux)'),
              _LineupBuilder(
                players: _homePlayers,
                lineup: _homeLineup,
                onChanged: (lineup) => setState(() => _homeLineup = lineup),
              ),
              const SizedBox(height: 12),
            ],

            // Date & time
            _SectionTitle(title: 'Date et heure'),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickDate,
                    icon: const Icon(Icons.calendar_today),
                    label: Text(
                      '${_gameDate.day}/${_gameDate.month}/${_gameDate.year}',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickTime,
                    icon: const Icon(Icons.access_time),
                    label: Text(_gameTime.format(context)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Location
            TextFormField(
              controller: _locationCtrl,
              decoration: const InputDecoration(
                labelText: 'Emplacement',
                hintText: 'Ex: Parc Jarry — Terrain 1',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on),
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Requis' : null,
            ),
            const SizedBox(height: 12),

            // Innings
            Row(
              children: [
                const Text('Nombre de manches:',
                    style: TextStyle(fontWeight: FontWeight.w500)),
                const SizedBox(width: 12),
                SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(value: 7, label: Text('7')),
                    ButtonSegment(value: 9, label: Text('9')),
                  ],
                  selected: {_totalInnings},
                  onSelectionChanged: (s) =>
                      setState(() => _totalInnings = s.first),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Start button
            ElevatedButton.icon(
              onPressed: _isCreating || _homeTeam == null || _awayTeam == null
                  ? null
                  : _startGame,
              icon: _isCreating
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.play_arrow),
              label: const Text('Commencer la partie'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                textStyle: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadPlayers(Team team, {required bool isHome}) async {
    await context.read<TeamProvider>().loadPlayers(team.id);
    if (mounted) {
      setState(() {
        final players = context.read<TeamProvider>().playersForTeam(team.id);
        if (isHome) {
          _homePlayers = players;
        } else {
          _awayPlayers = players;
        }
      });
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _gameDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) setState(() => _gameDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _gameTime,
    );
    if (picked != null) setState(() => _gameTime = picked);
  }

  Future<void> _startGame() async {
    if (!_formKey.currentState!.validate()) return;
    if (_homeTeam == null || _awayTeam == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sélectionnez les deux équipes')),
      );
      return;
    }

    setState(() => _isCreating = true);

    final gameDateTime = DateTime(
      _gameDate.year, _gameDate.month, _gameDate.day,
      _gameTime.hour, _gameTime.minute,
    );

    final game = await context.read<GameProvider>().createGame(
      homeTeamId: _homeTeam!.id,
      awayTeamId: _awayTeam!.id,
      homeTeamName: _homeTeam!.fullName,
      awayTeamName: _awayTeam!.fullName,
      gameDate: gameDateTime,
      location: _locationCtrl.text.trim(),
      homeLineup: _homeLineup.isEmpty
          ? _homePlayers.map((p) => p.id).toList()
          : _homeLineup,
      awayLineup: _awayLineup.isEmpty
          ? _awayPlayers.map((p) => p.id).toList()
          : _awayLineup,
      totalInnings: _totalInnings,
    );

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => LiveScoringScreen(gameId: game.id),
        ),
      );
    }
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1B2A3B),
            ),
      ),
    );
  }
}

class _TeamDropdown extends StatelessWidget {
  final String label;
  final List<Team> teams;
  final Team? selected;
  final String? excluded;
  final ValueChanged<Team?> onChanged;

  const _TeamDropdown({
    required this.label,
    required this.teams,
    required this.selected,
    required this.onChanged,
    this.excluded,
  });

  @override
  Widget build(BuildContext context) {
    final available = teams.where((t) => t.id != excluded).toList();
    return DropdownButtonFormField<Team>(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      value: selected,
      items: available
          .map((t) => DropdownMenuItem(value: t, child: Text(t.fullName)))
          .toList(),
      onChanged: onChanged,
      validator: (v) => v == null ? 'Requis' : null,
    );
  }
}

class _LineupBuilder extends StatefulWidget {
  final List<Player> players;
  final List<String> lineup;
  final ValueChanged<List<String>> onChanged;

  const _LineupBuilder({
    required this.players,
    required this.lineup,
    required this.onChanged,
  });

  @override
  State<_LineupBuilder> createState() => _LineupBuilderState();
}

class _LineupBuilderState extends State<_LineupBuilder> {
  late List<String> _lineup;

  @override
  void initState() {
    super.initState();
    _lineup = widget.lineup.isNotEmpty
        ? List.from(widget.lineup)
        : widget.players.map((p) => p.id).toList();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => widget.onChanged(_lineup));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ordre de frappe (glisser pour réorganiser)',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 6),
        ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _lineup.length,
          buildDefaultDragHandles: true,
          onReorder: (old, new_) {
            setState(() {
              if (new_ > old) new_--;
              final item = _lineup.removeAt(old);
              _lineup.insert(new_, item);
            });
            widget.onChanged(_lineup);
          },
          itemBuilder: (_, i) {
            final pid = _lineup[i];
            final player = widget.players.firstWhere(
              (p) => p.id == pid,
              orElse: () => widget.players[i % widget.players.length],
            );
            return ListTile(
              key: ValueKey(pid),
              dense: true,
              leading: CircleAvatar(
                radius: 14,
                backgroundColor: Colors.blueGrey,
                child: Text(
                  '${i + 1}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold),
                ),
              ),
              title: Text('${player.name} (#${player.number})'),
              subtitle: Text(player.position),
              trailing: const Icon(Icons.drag_handle),
            );
          },
        ),
      ],
    );
  }
}
