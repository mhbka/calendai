import 'package:flutter/material.dart';
import 'package:namer_app/main.dart';
import 'package:namer_app/models/calendar_event.dart';
import 'package:namer_app/services/calendar_api_service.dart';
import 'package:namer_app/services/notification_service.dart';
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
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  bool _isLoading = false;

  List<CalendarEvent> get events => _events;
  DateTime get focusedDay => _focusedDay;
  DateTime? get selectedDay => _selectedDay;
  bool get isLoading => _isLoading;

  // methods
  List<CalendarEvent> getEventsForDay(DateTime day) {
    return _events.where((event) {
      return isSameDay(event.startTime, day);
    }).toList();
  }

  void setSelectedDay(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
      notifyListeners();
    }
  }

  void setFocusedDay(DateTime focusedDay) {
    _focusedDay = focusedDay;
    loadEvents();
  }

  Future<void> loadEvents() async {
    _setLoading(true);
    try {
      final startOfMonth = DateTime(_focusedDay.year, _focusedDay.month, 1);
      final endOfMonth = DateTime(_focusedDay.year, _focusedDay.month + 1, 0);
      
      final events = await CalendarApiService.fetchEvents(startOfMonth, endOfMonth);
      _events = events;
      
      // Schedule reminders for all events
      for (final event in events) {
        NotificationService.scheduleEventReminder(event);
      }
      
      notifyListeners();
    } catch (e) {
      rethrow; // Let the UI handle the error display
    } finally {
      _setLoading(false);
    }
  }

  Future<CalendarEvent> saveEvent({
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
        
        // Update local list
        final index = _events.indexWhere((e) => e.id == existingEvent.id);
        if (index != -1) {
          _events[index] = savedEvent;
        }
      } else {
        // Create new event
        final newEvent = CalendarEvent(
          id: uuid.v4(),
          title: title,
          description: description,
          location: location,
          startTime: startTime,
          endTime: endTime,
        );
        savedEvent = await CalendarApiService.createEvent(newEvent);
        _events.add(savedEvent);
      }

      // Schedule reminder
      NotificationService.scheduleEventReminder(savedEvent);
      notifyListeners();
      
      return savedEvent;
    } catch (e) {
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

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