import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:namer_app/main.dart';
import 'package:namer_app/models/recurring_event.dart';
import 'package:namer_app/models/recurring_event_group.dart';
import 'package:namer_app/services/base_api_service.dart';
import 'package:uuid/enums.dart';

/// For interacting with the recurring event groups' API.
class RecurringEventGroupsApiService extends BaseApiService {
  static String baseUrl = "${envVars.apiBaseUrl}/recurring_event_groups";

  /// Fetch all recurring event groups for a user.
  static Future<List<RecurringEventGroup>> fetchAllGroups() async {
    return BaseApiService.handleRequest(
      () => http.get(
        Uri.parse(baseUrl), 
        headers: BaseApiService.headers
      ),
      (response) => BaseApiService.parseJsonList(response.body, RecurringEventGroup.fromJson),
    );
  }

  /// Fetch a group's data.
  static Future<RecurringEventGroup> fetchGroup(String groupId) async {
    return BaseApiService.handleRequest(
      () => http.get(
        Uri.parse("$baseUrl/$groupId"), 
        headers: BaseApiService.headers
      ),
      (response) => RecurringEventGroup.fromJson(jsonDecode(response.body)),
    );
  }

  /// Fetch all recurring events under a group.
  /// If `groupId` is null, fetch all ungrouped events.
  static Future<List<RecurringEvent>> fetchEventsUnderGroup(String? groupId) async {
    if (groupId == null || groupId == Namespace.nil.value) {
      groupId = "ungrouped";
    }
    return BaseApiService.handleRequest(
      () => http.get(
        Uri.parse("$baseUrl/$groupId/events"), 
        headers: BaseApiService.headers
      ),
      (response) => BaseApiService.parseJsonList(response.body, RecurringEvent.fromJson),
    );
  }

  /// Create new groups.
  static Future<void> createGroup(RecurringEventGroup group) async {
    return BaseApiService.handleRequest(
      () => http.post(
        Uri.parse(baseUrl), 
        body: json.encode(group), 
        headers: BaseApiService.headers
      ),
      (response) => {},
      validStatusCodes: [200, 201],
    );
  }

  /// Update a group.
  static Future<void> updateGroup(RecurringEventGroup group) async {
    return BaseApiService.handleRequest(
      () => http.put(
        Uri.parse(baseUrl), 
        body: json.encode(group), 
        headers: BaseApiService.headers
      ),
      (response) => {},
      validStatusCodes: [200, 201],
    );
  }

  /// Delete a group.
  static Future<void> deleteGroup(String groupId) async {
    return BaseApiService.handleRequest(
      () => http.delete(
        Uri.parse("$baseUrl/$groupId"), 
        headers: BaseApiService.headers
      ),
      (response) => {},
      validStatusCodes: [200, 204],
    );
  }

  /// Move a recurring event between groups.
  static Future<void> moveEventBetweenGroups(
    String eventId,
    String newGroupId
  ) async {
    return BaseApiService.handleRequest(
      () => http.get(
        Uri.parse("$baseUrl/$newGroupId/move/$eventId"), 
        headers: BaseApiService.headers
      ),
      (response) {},
    );
  }
}