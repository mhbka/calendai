import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:namer_app/main.dart';
import 'package:namer_app/models/calendar_event.dart';
import 'package:namer_app/services/base_api_service.dart';

/// For interacting with the calendar (event) API.
class CalendarApiService extends BaseApiService {
  static String baseUrl = "${envVars['api_base_url']!}/calendar_events";

  /// Fetch events for a date range.
  static Future<List<CalendarEvent>> fetchEvents(DateTime start, DateTime end) async {
    return BaseApiService.handleRequest(
      () => http.get(
        Uri.parse('$baseUrl?start=${start.toUtc().toIso8601String()}&end=${end.toUtc().toIso8601String()}'),
        headers: BaseApiService.headers,
      ),
      (response) => BaseApiService.parseJsonList(response.body, CalendarEvent.fromJson),
    );
  }

  /// Creates new calendar events.
  static Future<void> createEvents(List<CalendarEvent> events) async {
    return BaseApiService.handleRequest(
      () => http.post(
        Uri.parse(baseUrl),
        headers: BaseApiService.headers,
        body: json.encode(events.map((event) => event.toJson()).toList()),
      ),
      (response) => {},
      validStatusCodes: [200, 201],
    );
  }

  /// Update an existing calendar event.
  static Future<void> updateEvent(CalendarEvent event) async {
    return BaseApiService.handleRequest(
      () => http.put(
        Uri.parse(baseUrl),
        headers: BaseApiService.headers,
        body: json.encode(event.toJson()),
      ),
      (response) => {},
    );
  }

  /// Delete a calendar event.
  static Future<void> deleteEvent(String eventId) async {
    return BaseApiService.handleRequest(
      () => http.delete(
        Uri.parse('$baseUrl/$eventId'),
        headers: BaseApiService.headers,
      ),
      (response) => {},
      validStatusCodes: [200, 204],
    );
  }
}