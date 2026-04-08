import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../providers/schedule_provider.dart';
import '../../providers/team_provider.dart';
import '../../models/schedule_event.dart';
import '../../models/team.dart';
import '../../widgets/ad_banner_widget.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarFormat _calFormat = CalendarFormat.month;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ScheduleProvider>().loadEvents();
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheduleProvider = context.watch<ScheduleProvider>();
    final selectedEvents =
        scheduleProvider.eventsForDay(_selectedDay ?? _focusedDay);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendrier'),
        backgroundColor: const Color(0xFF1B2A3B),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showEventDialog(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Calendar
          TableCalendar(
            firstDay: DateTime(2020),
            lastDay: DateTime(2030),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            calendarFormat: _calFormat,
            eventLoader: (day) => scheduleProvider.eventsForDay(day),
            onDaySelected: (selected, focused) {
              setState(() {
                _selectedDay = selected;
                _focusedDay = focused;
              });
            },
            onFormatChanged: (format) =>
                setState(() => _calFormat = format),
            onPageChanged: (focused) =>
                setState(() => _focusedDay = focused),
            calendarStyle: const CalendarStyle(
              todayDecoration: BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: Color(0xFF1B2A3B),
                shape: BoxShape.circle,
              ),
              markerDecoration: BoxDecoration(
                color: Colors.amber,
                shape: BoxShape.circle,
              ),
            ),
            headerStyle: const HeaderStyle(
              formatButtonShowsNext: false,
              titleCentered: true,
            ),
          ),
          const Divider(height: 1),

          // Events list for selected day
          Expanded(
            child: selectedEvents.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.event_available,
                            size: 48, color: Colors.grey),
                        const SizedBox(height: 8),
                        const Text('Aucun match ce jour'),
                        const SizedBox(height: 12),
                        TextButton.icon(
                          onPressed: () => _showEventDialog(context),
                          icon: const Icon(Icons.add),
                          label: const Text('Ajouter un match'),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: selectedEvents.length,
                    itemBuilder: (_, i) =>
                        _EventCard(event: selectedEvents[i]),
                  ),
          ),
          const AdBannerWidget(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showEventDialog(context),
        backgroundColor: const Color(0xFF1B2A3B),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _showEventDialog(BuildContext context, {ScheduleEvent? event}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _EventFormSheet(
        initialDate: _selectedDay,
        event: event,
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  final ScheduleEvent event;
  const _EventCard({required this.event});

  @override
  Widget build(BuildContext context) {
    final timeStr =
        DateFormat('HH:mm').format(event.dateTime);
    final isPast = event.isPast;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      opacity: isPast ? 0.7 : 1.0,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.access_time,
                    size: 14,
                    color: isPast ? Colors.grey : Colors.blue),
                const SizedBox(width: 4),
                Text(
                  timeStr,
                  style: TextStyle(
                    color: isPast ? Colors.grey : Colors.blue,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                if (isPast) ...[
                  const SizedBox(width: 8),
                  const Text(
                    'Passé',
                    style: TextStyle(color: Colors.grey, fontSize: 11),
                  ),
                ],
                const Spacer(),
                PopupMenuButton<String>(
                  onSelected: (v) {
                    if (v == 'delete') {
                      context
                          .read<ScheduleProvider>()
                          .deleteEvent(event.id);
                    } else if (v == 'edit') {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        builder: (_) => _EventFormSheet(event: event),
                      );
                    }
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                        value: 'edit', child: Text('Modifier')),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('Supprimer',
                          style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    event.awayTeamName,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text('@',
                      style: TextStyle(color: Colors.grey)),
                ),
                Expanded(
                  child: Text(
                    event.homeTeamName,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.location_on,
                    size: 13, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    event.location,
                    style: const TextStyle(
                        color: Colors.grey, fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            if (event.notes != null && event.notes!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                event.notes!,
                style: const TextStyle(
                    color: Colors.grey, fontSize: 11,
                    fontStyle: FontStyle.italic),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Event form sheet ─────────────────────────────────────────────────────────

class _EventFormSheet extends StatefulWidget {
  final DateTime? initialDate;
  final ScheduleEvent? event;

  const _EventFormSheet({this.initialDate, this.event});

  @override
  State<_EventFormSheet> createState() => _EventFormSheetState();
}

class _EventFormSheetState extends State<_EventFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _locationCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  Team? _homeTeam;
  Team? _awayTeam;
  late DateTime _date;
  late TimeOfDay _time;

  @override
  void initState() {
    super.initState();
    final event = widget.event;
    _date = event?.dateTime ?? widget.initialDate ?? DateTime.now();
    _time = event != null
        ? TimeOfDay.fromDateTime(event.dateTime)
        : const TimeOfDay(hour: 18, minute: 0);
    _locationCtrl.text = event?.location ?? '';
    _notesCtrl.text = event?.notes ?? '';
  }

  @override
  void dispose() {
    _locationCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final teams = context.watch<TeamProvider>().teams;
    final isEditing = widget.event != null;

    return Padding(
      padding: EdgeInsets.fromLTRB(
          16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 16),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isEditing ? 'Modifier le match' : 'Ajouter un match',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _TeamDropdown(
                      label: 'Visiteurs',
                      teams: teams,
                      selected: _awayTeam,
                      excluded: _homeTeam?.id,
                      onChanged: (t) => setState(() => _awayTeam = t),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text('@'),
                  ),
                  Expanded(
                    child: _TeamDropdown(
                      label: 'Locaux',
                      teams: teams,
                      selected: _homeTeam,
                      excluded: _awayTeam?.id,
                      onChanged: (t) => setState(() => _homeTeam = t),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickDate,
                      icon: const Icon(Icons.calendar_today, size: 16),
                      label: Text(
                        '${_date.day}/${_date.month}/${_date.year}',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickTime,
                      icon: const Icon(Icons.access_time, size: 16),
                      label: Text(
                        _time.format(context),
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _locationCtrl,
                decoration: const InputDecoration(
                  labelText: 'Emplacement',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on),
                  isDense: true,
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Requis' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notesCtrl,
                decoration: const InputDecoration(
                  labelText: 'Notes (optionnel)',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B2A3B),
                    foregroundColor: Colors.white,
                  ),
                  child: Text(isEditing ? 'Sauvegarder' : 'Ajouter'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time,
    );
    if (picked != null) setState(() => _time = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_homeTeam == null || _awayTeam == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sélectionnez les deux équipes')),
      );
      return;
    }

    final provider = context.read<ScheduleProvider>();
    final dateTime = DateTime(
      _date.year, _date.month, _date.day,
      _time.hour, _time.minute,
    );

    if (widget.event == null) {
      await provider.addEvent(
        homeTeamId: _homeTeam!.id,
        awayTeamId: _awayTeam!.id,
        homeTeamName: _homeTeam!.fullName,
        awayTeamName: _awayTeam!.fullName,
        dateTime: dateTime,
        location: _locationCtrl.text.trim(),
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      );
    } else {
      await provider.updateEvent(widget.event!.copyWith(
        homeTeamId: _homeTeam!.id,
        awayTeamId: _awayTeam!.id,
        homeTeamName: _homeTeam!.fullName,
        awayTeamName: _awayTeam!.fullName,
        dateTime: dateTime,
        location: _locationCtrl.text.trim(),
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      ));
    }

    if (mounted) Navigator.pop(context);
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
            const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        isDense: true,
      ),
      value: selected,
      isExpanded: true,
      items: available.map((t) {
        return DropdownMenuItem(
          value: t,
          child: Text(t.fullName,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12)),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }
}
