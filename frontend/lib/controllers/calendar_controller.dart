import 'package:flutter/material.dart';
import 'package:calendai/models/calendar_event.dart';
import 'package:calendai/models/recurring_calendar_event.dart';
import 'package:calendai/services/calendar_api_service.dart';
import 'package:calendai/services/notification_service.dart';
import 'package:calendai/services/recurring_events_api_service.dart';
import 'package:calendai/services/service_exception.dart';
import 'package:calendai/utils/alerts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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

  /// Gets events for the selected day.
  List<CalendarEvent> getEventsForDay(DateTime day) {
    return _events
      .where((event) => isSameDay(event.startTime, day))
      .toList();
  }

  /// Gets recurring events for the current day.
  List<RecurringCalendarEvent> getRecurringEventsForDay(DateTime day) {
    return _recurringEvents
      .where((event) => isSameDay(event.startTime, day))
      .toList();
  }

  /// Get all events for the day (recurring events are mapped to `CalendarEvent`).
  List<CalendarEvent> getAllEventsForDay(DateTime day) {
    var events = _events
      .where((event) => isSameDay(event.startTime, day))
      .toList();
    var recurringEvents = _recurringEvents
      .where((event) => isSameDay(event.startTime, day))
      .map((e) => e.recurringToCalendarEvent())
      .toList();
    return [...events, ...recurringEvents];
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
      
      notifyListeners();
    } catch (e) {
      if (e is ServiceException) {
        if (e.statusCode == 401) {
          await Supabase.instance.client.auth.signOut();
        }
      }
      rethrow; // Let the UI handle the error display
    } finally {
      _setLoading(false);
    }
  }

  /// Saves a new event/updates the current event.
  Future<void> saveEvent(CalendarEvent event,  bool isNewEvent) async {
    _setLoading(true);
    try {
      if (isNewEvent) {
        await CalendarApiService.createEvents([event]);
      } 
      else {
        await CalendarApiService.updateEvent(event);
      }
    } catch (e) {
      rethrow;
    } finally {
      await loadEvents();
      _setLoading(false);
    }
  }

  /// Deletes a chosen event.
  Future<void> deleteEvent(CalendarEvent event) async {
    _setLoading(true);
    try {
      if (event.id != null) {
        await CalendarApiService.deleteEvent(event.id!);
        NotificationService.cancelEventNotification(event.id!);
        _events.removeWhere((e) => e.id == event.id);
        notifyListeners();
      }
      else {
        throw ArgumentError("No ID was found for this event");
      }
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