import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/team_provider.dart';
import '../../models/team.dart';
import 'team_detail_screen.dart';

class TeamsScreen extends StatelessWidget {
  const TeamsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TeamProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Équipes'),
        backgroundColor: const Color(0xFF1B2A3B),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showTeamDialog(context),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : provider.teams.isEmpty
                    ? _EmptyTeams(onAdd: () => _showTeamDialog(context))
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: provider.teams.length,
                        itemBuilder: (_, i) =>
                            _TeamCard(team: provider.teams[i]),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showTeamDialog(context),
        backgroundColor: const Color(0xFF1B2A3B),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _showTeamDialog(BuildContext context, {Team? team}) {
    showDialog(
      context: context,
      builder: (_) => _TeamFormDialog(team: team),
    );
  }
}

class _EmptyTeams extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyTeams({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.groups_outlined, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('Aucune équipe', style: TextStyle(fontSize: 18)),
          const SizedBox(height: 8),
          const Text(
            'Créez votre première équipe pour commencer',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('Créer une équipe'),
          ),
        ],
      ),
    );
  }
}

class _TeamCard extends StatelessWidget {
  final Team team;
  const _TeamCard({required this.team});

  @override
  Widget build(BuildContext context) {
    final color = _parseColor(team.logoColor);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color,
          child: Text(
            team.name.isNotEmpty ? team.name[0].toUpperCase() : '?',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          team.fullName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: const Text('Appuyer pour voir les joueurs'),
        trailing: PopupMenuButton<String>(
          onSelected: (v) => _handleMenu(context, v),
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'edit', child: Text('Modifier')),
            const PopupMenuItem(
              value: 'delete',
              child: Text('Supprimer', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => TeamDetailScreen(team: team)),
        ),
      ),
    );
  }

  void _handleMenu(BuildContext context, String action) {
    if (action == 'edit') {
      showDialog(
        context: context,
        builder: (_) => _TeamFormDialog(team: team),
      );
    } else if (action == 'delete') {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Supprimer l\'équipe'),
          content: Text(
              'Êtes-vous sûr de vouloir supprimer ${team.fullName} ?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () {
                context.read<TeamProvider>().deleteTeam(team.id);
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

  Color _parseColor(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return Colors.blueGrey;
    }
  }
}

class _TeamFormDialog extends StatefulWidget {
  final Team? team;
  const _TeamFormDialog({this.team});

  @override
  State<_TeamFormDialog> createState() => _TeamFormDialogState();
}

class _TeamFormDialogState extends State<_TeamFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _cityCtrl;
  String _selectedColor = '#2196F3';

  final List<Map<String, dynamic>> _colors = [
    {'label': 'Bleu', 'hex': '#2196F3'},
    {'label': 'Rouge', 'hex': '#F44336'},
    {'label': 'Vert', 'hex': '#4CAF50'},
    {'label': 'Orange', 'hex': '#FF9800'},
    {'label': 'Violet', 'hex': '#9C27B0'},
    {'label': 'Noir', 'hex': '#212121'},
    {'label': 'Marine', 'hex': '#1B2A3B'},
    {'label': 'Or', 'hex': '#FFC107'},
  ];

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.team?.name ?? '');
    _cityCtrl = TextEditingController(text: widget.team?.city ?? '');
    _selectedColor = widget.team?.logoColor ?? '#2196F3';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _cityCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.team != null;
    return AlertDialog(
      title: Text(isEditing ? 'Modifier l\'équipe' : 'Nouvelle équipe'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _cityCtrl,
                decoration: const InputDecoration(
                  labelText: 'Ville',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Requis' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nom de l\'équipe',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Requis' : null,
              ),
              const SizedBox(height: 12),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('Couleur'),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _colors.map((c) {
                  final hex = c['hex'] as String;
                  final color =
                      Color(int.parse(hex.replaceFirst('#', '0xFF')));
                  final isSelected = hex == _selectedColor;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedColor = hex),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: isSelected
                            ? Border.all(
                                color: Colors.white, width: 3)
                            : null,
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: color.withAlpha(128),
                                  blurRadius: 6,
                                )
                              ]
                            : null,
                      ),
                      child: isSelected
                          ? const Icon(Icons.check,
                              color: Colors.white, size: 18)
                          : null,
                    ),
                  );
                }).toList(),
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
          child: Text(isEditing ? 'Sauvegarder' : 'Créer'),
        ),
      ],
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final provider = context.read<TeamProvider>();
    if (widget.team == null) {
      await provider.addTeam(
        name: _nameCtrl.text.trim(),
        city: _cityCtrl.text.trim(),
        logoColor: _selectedColor,
      );
    } else {
      await provider.updateTeam(widget.team!.copyWith(
        name: _nameCtrl.text.trim(),
        city: _cityCtrl.text.trim(),
        logoColor: _selectedColor,
      ));
    }
    if (mounted) Navigator.pop(context);
  }
}
