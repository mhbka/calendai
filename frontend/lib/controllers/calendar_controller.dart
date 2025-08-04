import 'package:flutter/material.dart';
import 'package:namer_app/models/calendar_event.dart';
import 'package:namer_app/models/recurring_calendar_event.dart';
import 'package:namer_app/services/calendar_api_service.dart';
import 'package:namer_app/services/notification_service.dart';
import 'package:namer_app/services/recurring_events_api_service.dart';
import 'package:table_calendar/table_calendar.dart';

class CalendarController extends ChangeNotifier {
  // singleton stuff

  CalendarController._internal() {
    _selectedDay = DateTime.now();
    loadEvents();
  }

  static final CalendarController _instance = CalendarController._internal();

  factory CalendarController() {
    return _instance;
  }

  static CalendarController get instance => _instance;

  // members

  List<CalendarEvent> _events = [];
  List<RecurringCalendarEvent> _recurringEvents = [];
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  bool _isLoading = false;

  List<CalendarEvent> get events => _events;
  DateTime get focusedDay => _focusedDay;
  DateTime? get selectedDay => _selectedDay;
  bool get isLoading => _isLoading;

  // methods

  /// Gets all events for the selected day.
  List<CalendarEvent> getEventsForDay(DateTime day) {
    var normalEvents = _events
      .where((event) => isSameDay(event.startTime, day))
      .toList();
    var recurringEvents = _recurringEvents
      .where((event) => isSameDay(event.startTime, day))
      .map((e) => e.recurringToCalendarEvent())
      .toList();
    return [...normalEvents, ...recurringEvents];
  }

  /// Sets the selected day.
  void setSelectedDay(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
      notifyListeners();
    }
  }

  /// Set the focused day.
  void setFocusedDay(DateTime focusedDay) {
    _focusedDay = focusedDay;
    loadEvents();
  }

  /// Loads all calendar events and recurring calendar events between the start and end datetimes.
  Future<void> loadEvents() async {
    _setLoading(true);
    try {
      final startOfMonth = DateTime(_focusedDay.year, _focusedDay.month, 1);
      final endOfMonth = DateTime(_focusedDay.year, _focusedDay.month + 1, 0);
      
      _events = await CalendarApiService.fetchEvents(startOfMonth, endOfMonth);
      _recurringEvents = await RecurringEventsApiService.fetchCalendarEvents(startOfMonth, endOfMonth);
      
      // Schedule reminders for all events
      for (final event in _events) {
        NotificationService.scheduleEventReminder(event);
      }
      for (final event in _recurringEvents) {
        NotificationService.scheduleEventReminder(event.recurringToCalendarEvent());
      }
      
      notifyListeners();
    } catch (e) {
      rethrow; // Let the UI handle the error display
    } finally {
      _setLoading(false);
    }
  }

  /// Saves a new event/updates the current event.
  Future<void> saveEvent({
    CalendarEvent? existingEvent,
    required String title,
    required String description,
    String? location,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    _setLoading(true);
    try {
      CalendarEvent savedEvent;
      
      if (existingEvent != null) {
        savedEvent = existingEvent.copyWith(
          title: title,
          description: description,
          location: location,
          startTime: startTime,
          endTime: endTime,
        );
        await CalendarApiService.updateEvent(savedEvent);
        await loadEvents();
      } 
      else {
        final newEvent = CalendarEvent(
          id: "-1", // new events don't have IDs
          title: title,
          description: description,
          location: location,
          startTime: startTime,
          endTime: endTime,
        );
        await CalendarApiService.createEvents([newEvent]);
        await loadEvents();
      }
    } catch (e) {
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Deletes a chosen event.
  Future<void> deleteEvent(CalendarEvent event) async {
    _setLoading(true);
    try {
      await CalendarApiService.deleteEvent(event.id);
      NotificationService.cancelEventReminder(event.id);
      
      _events.removeWhere((e) => e.id == event.id);
      notifyListeners();
    } catch (e) {
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}