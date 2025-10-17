import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:namer_app/main.dart';
import 'package:namer_app/models/recurring_calendar_event.dart';
import 'package:namer_app/models/recurring_event.dart';
import 'package:namer_app/models/recurring_event_exception.dart';
import 'package:namer_app/services/base_api_service.dart';
import 'package:namer_app/services/recurring_event_groups_api_service.dart';

/// For interacting with the recurring events' API.
class RecurringEventsApiService extends BaseApiService {
  static String baseUrl = "${envVars.apiBaseUrl}/recurring_events";

  /// Fetch recurring events under a group.
  /// 
  /// If `groupId` is null, fetch all ungrouped events.
  static Future<List<RecurringEvent>> fetchEvents(String? groupId) async {
    return await RecurringEventGroupsApiService.fetchEventsUnderGroup(groupId);
  }

  /// Fetch recurring calendar events for a date range.
  static Future<List<RecurringCalendarEvent>> fetchCalendarEvents(DateTime start, DateTime end) async {
    return BaseApiService.handleRequest(
      () => http.get(
        Uri.parse('$baseUrl?start=${start.toUtc().toIso8601String()}&end=${end.toUtc().toIso8601String()}'),
        headers: BaseApiService.headers,
      ),
      (response) => BaseApiService.parseJsonList(response.body, RecurringCalendarEvent.fromJson),
    );
  }

  /// Create events.
  static Future<void> createEvents(List<RecurringEvent> events) async {
    return BaseApiService.handleRequest(
      () => http.post(
        Uri.parse(baseUrl), 
        body: json.encode(events),
        headers: BaseApiService.headers
      ),
      (response) {},
    );
  }

  /// Update an event.
  static Future<void> updateEvent(RecurringEvent event) async {
    return BaseApiService.handleRequest(
      () => http.put(
        Uri.parse(baseUrl), 
        body: json.encode(event),
        headers: BaseApiService.headers
      ),
      (response) {},
    );
  }

  /// Delete an event.
  static Future<void> deleteEvent(String eventId) async {
    return BaseApiService.handleRequest(
      () => http.delete(
        Uri.parse("$baseUrl/$eventId"), 
        headers: BaseApiService.headers
      ),
      (response) {},
    );
  }

  /// Create an event exception (modifies/deletes a single instance of a recurring event).
  static Future<void> createEventException(RecurringEventException exception) async {
    return BaseApiService.handleRequest(
      () => http.post(
        Uri.parse("$baseUrl/exception"), 
        body: json.encode(exception),
        headers: BaseApiService.headers
      ),
      (response) {},
    );
  }

  /// Update an event exception.
  static Future<void> updateEventException(RecurringEventException exception) async {
    return BaseApiService.handleRequest(
      () => http.put(
        Uri.parse("$baseUrl/exception"), 
        body: json.encode(exception),
        headers: BaseApiService.headers
      ),
      (response) {},
    );
  }
}