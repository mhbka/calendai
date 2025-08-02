import 'package:namer_app/main.dart';
import 'package:namer_app/models/recurring_event.dart';
import 'package:namer_app/services/base_api_service.dart';
import 'package:namer_app/services/recurring_event_groups_api_service.dart';

/// For interacting with the recurring events' API.
class RecurringEventsApiService extends BaseApiService {
  static String baseUrl = "${envVars['api_base_url']!}/recurring_event_groups";

  /// Fetch recurring events under a group.
  /// If `groupId` is null, fetch all ungrouped events.
  static Future<List<RecurringEvent>> fetchEvents(String? groupId) async {
    return await RecurringEventGroupsApiService.fetchEventsUnderGroup(groupId);
  }

  /// Create an event, optionally under a group.
  static Future<void> createEvent(RecurringEvent event, String? groupId) async {

  }

  /// Update an event.
  static Future<void> updateEvent(RecurringEvent event) async {

  }

  /// Delete an event.
  static Future<void> deleteEvent(String eventId) async {

  }
}