import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/schedule_event.dart';
import '../database/database_helper.dart';

class ScheduleProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper();
  final _uuid = const Uuid();

  List<ScheduleEvent> _events = [];
  bool _isLoading = false;

  List<ScheduleEvent> get events => List.unmodifiable(_events);
  bool get isLoading => _isLoading;

  List<ScheduleEvent> get upcomingEvents =>
      _events.where((e) => !e.isPast).toList();

  List<ScheduleEvent> get pastEvents =>
      _events.where((e) => e.isPast).toList();

  List<ScheduleEvent> eventsForDay(DateTime day) {
    return _events.where((e) {
      final d = e.dateTime;
      return d.year == day.year && d.month == day.month && d.day == day.day;
    }).toList();
  }

  Future<void> loadEvents() async {
    _isLoading = true;
    notifyListeners();
    _events = await _db.getScheduleEvents();
    _isLoading = false;
    notifyListeners();
  }

  Future<ScheduleEvent> addEvent({
    required String homeTeamId,
    required String awayTeamId,
    required String homeTeamName,
    required String awayTeamName,
    required DateTime dateTime,
    required String location,
    String? notes,
  }) async {
    final event = ScheduleEvent(
      id: _uuid.v4(),
      homeTeamId: homeTeamId,
      awayTeamId: awayTeamId,
      homeTeamName: homeTeamName,
      awayTeamName: awayTeamName,
      dateTime: dateTime,
      location: location,
      notes: notes,
    );
    await _db.insertScheduleEvent(event);
    _events.add(event);
    _events.sort((a, b) => a.dateTime.compareTo(b.dateTime));
    notifyListeners();
    return event;
  }

  Future<void> updateEvent(ScheduleEvent event) async {
    await _db.updateScheduleEvent(event);
    final idx = _events.indexWhere((e) => e.id == event.id);
    if (idx != -1) {
      _events[idx] = event;
      _events.sort((a, b) => a.dateTime.compareTo(b.dateTime));
      notifyListeners();
    }
  }

  Future<void> deleteEvent(String id) async {
    await _db.deleteScheduleEvent(id);
    _events.removeWhere((e) => e.id == id);
    notifyListeners();
  }

  Future<void> linkGameToEvent(String eventId, String gameId) async {
    final idx = _events.indexWhere((e) => e.id == eventId);
    if (idx != -1) {
      final updated = _events[idx].copyWith(linkedGameId: gameId);
      await _db.updateScheduleEvent(updated);
      _events[idx] = updated;
      notifyListeners();
    }
  }
}
