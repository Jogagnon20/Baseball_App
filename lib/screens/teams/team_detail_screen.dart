import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/team_provider.dart';
import '../../models/team.dart';
import '../../models/player.dart';
import '../../widgets/ad_banner_widget.dart';

class TeamDetailScreen extends StatefulWidget {
  final Team team;
  const TeamDetailScreen({super.key, required this.team});

  @override
  State<TeamDetailScreen> createState() => _TeamDetailScreenState();
}

class _TeamDetailScreenState extends State<TeamDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TeamProvider>().loadPlayers(widget.team.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TeamProvider>();
    final players = provider.playersForTeam(widget.team.id);
    final teamColor =
        Color(int.parse(widget.team.logoColor.replaceFirst('#', '0xFF')));

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.team.fullName),
        backgroundColor: teamColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: () => _showPlayerDialog(context),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: players.isEmpty
                ? _EmptyPlayers(onAdd: () => _showPlayerDialog(context))
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: players.length,
                    itemBuilder: (_, i) => _PlayerCard(
                      player: players[i],
                      teamColor: teamColor,
                      onEdit: () => _showPlayerDialog(context, player: players[i]),
                      onDelete: () => _confirmDelete(context, players[i]),
                    ),
                  ),
          ),
          const AdBannerWidget(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showPlayerDialog(context),
        backgroundColor: teamColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add),
        label: const Text('Ajouter joueur'),
      ),
    );
  }

  void _showPlayerDialog(BuildContext context, {Player? player}) {
    showDialog(
      context: context,
      builder: (_) => _PlayerFormDialog(
        teamId: widget.team.id,
        player: player,
      ),
    );
  }

  void _confirmDelete(BuildContext context, Player player) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Supprimer le joueur'),
        content: Text('Supprimer ${player.name} (#${player.number}) ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              context
                  .read<TeamProvider>()
                  .deletePlayer(player.id, player.teamId);
              Navigator.pop(context);
            },
            child:
                const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _EmptyPlayers extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyPlayers({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.person_off, size: 64, color: Colors.grey),
          const SizedBox(height: 12),
          const Text('Aucun joueur dans cette équipe'),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.person_add),
            label: const Text('Ajouter un joueur'),
          ),
        ],
      ),
    );
  }
}

class _PlayerCard extends StatelessWidget {
  final Player player;
  final Color teamColor;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _PlayerCard({
    required this.player,
    required this.teamColor,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: teamColor,
          child: Text(
            '#${player.number}',
            style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(player.name,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('Position: ${player.position}'),
        trailing: PopupMenuButton<String>(
          onSelected: (v) {
            if (v == 'edit') onEdit();
            if (v == 'delete') onDelete();
          },
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'edit', child: Text('Modifier')),
            const PopupMenuItem(
              value: 'delete',
              child: Text('Supprimer', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlayerFormDialog extends StatefulWidget {
  final String teamId;
  final Player? player;
  const _PlayerFormDialog({required this.teamId, this.player});

  @override
  State<_PlayerFormDialog> createState() => _PlayerFormDialogState();
}

class _PlayerFormDialogState extends State<_PlayerFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _numberCtrl;
  String _position = 'P';

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.player?.name ?? '');
    _numberCtrl =
        TextEditingController(text: widget.player?.number.toString() ?? '');
    _position = widget.player?.position ?? 'P';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _numberCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.player != null;
    return AlertDialog(
      title: Text(isEditing ? 'Modifier le joueur' : 'Nouveau joueur'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nom du joueur',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.words,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Requis' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _numberCtrl,
                decoration: const InputDecoration(
                  labelText: 'Numéro de chandail',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Requis';
                  final n = int.tryParse(v.trim());
                  if (n == null || n < 0 || n > 99) {
                    return 'Numéro entre 0 et 99';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _position,
                decoration: const InputDecoration(
                  labelText: 'Position',
                  border: OutlineInputBorder(),
                ),
                items: Player.positions
                    .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                    .toList(),
                onChanged: (v) => setState(() => _position = v ?? 'P'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _save,
          child: Text(isEditing ? 'Sauvegarder' : 'Ajouter'),
        ),
      ],
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final provider = context.read<TeamProvider>();
    if (widget.player == null) {
      await provider.addPlayer(
        teamId: widget.teamId,
        name: _nameCtrl.text.trim(),
        number: int.parse(_numberCtrl.text.trim()),
        position: _position,
      );
    } else {
      await provider.updatePlayer(widget.player!.copyWith(
        name: _nameCtrl.text.trim(),
        number: int.parse(_numberCtrl.text.trim()),
        position: _position,
      ));
    }
    if (mounted) Navigator.pop(context);
  }
}
