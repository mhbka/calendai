import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:namer_app/models/calendar_event.dart';

class CalendarApiService {
  static const String baseUrl = 'https://your-backend-api.com/api';
  
  /// Fetch events for a date range
  static Future<List<CalendarEvent>> fetchEvents(DateTime start, DateTime end) async {
    try {
      // Stub implementation - replace with actual API call
      final response = await http.get(
        Uri.parse('$baseUrl/events?start=${start.toIso8601String()}&end=${end.toIso8601String()}'),
        headers: {'Content-Type': 'application/json'},
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => CalendarEvent.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load events');
      }
    } catch (e) {
      // Return mock data for now
      return _getMockEvents();
    }
  }

  static Future<CalendarEvent> createEvent(CalendarEvent event) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/events'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(event.toJson()),
      );
      
      if (response.statusCode == 201) {
        return CalendarEvent.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to create event');
      }
    } catch (e) {
      // Return the event with a generated ID for now
      return event.copyWith(id: DateTime.now().millisecondsSinceEpoch.toString());
    }
  }

  static Future<CalendarEvent> updateEvent(CalendarEvent event) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/events/${event.id}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(event.toJson()),
      );
      
      if (response.statusCode == 200) {
        return CalendarEvent.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to update event');
      }
    } catch (e) {
      return event;
    }
  }

  static Future<void> deleteEvent(String eventId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/events/$eventId'),
        headers: {'Content-Type': 'application/json'},
      );
      
      if (response.statusCode != 200) {
        throw Exception('Failed to delete event');
      }
    } catch (e) {
      // Silently handle for stub
    }
  }

  // Mock data for testing
  static List<CalendarEvent> _getMockEvents() {
    final now = DateTime.now();
    return [
      CalendarEvent(
        id: '1',
        title: 'Team Meeting',
        description: 'Weekly team sync',
        startTime: now.add(Duration(hours: 2)),
        endTime: now.add(Duration(hours: 3)),
        location: 'Conference Room A',
      ),
      CalendarEvent(
        id: '2',
        title: 'Doctor Appointment',
        description: 'Annual checkup',
        startTime: now.add(Duration(days: 1, hours: 10)),
        endTime: now.add(Duration(days: 1, hours: 11)),
        location: 'Medical Center',
      ),
    ];
  }
}