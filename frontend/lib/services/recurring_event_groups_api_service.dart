import 'dart:convert';
import 'dart:ui';
import 'package:http/http.dart' as http;
import 'package:namer_app/main.dart';
import 'package:namer_app/models/recurring_event.dart';
import 'package:namer_app/models/recurring_event_group.dart';
import 'package:namer_app/services/base_api_service.dart';

/// For interacting with the recurring event groups' API.
class RecurringEventGroupsApiService extends BaseApiService {
  static String baseUrl = "${envVars['api_base_url']!}/recurring_event_groups";

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

  /// Adds a new empty group.
  static Future<void> addGroup(
    String name,
    String? description,
    bool isActive,
    Color color,
    DateTime? startDate,
    DateTime? endDate
  ) async {
    final newGroup = RecurringEventGroup(
      name: name,
      id: "",
      description: description,
      isActive: isActive,
      color: color,
      startDate: startDate,
      endDate: endDate,
      recurringEvents: 0
    );
    final jsonGroup = json.encode(newGroup);

    return BaseApiService.handleRequest(
      () => http.post(
        Uri.parse(baseUrl), 
        body: jsonGroup, 
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

  /// Fetch recurring events under a group.
  static Future<List<RecurringEvent>> fetchEventsForGroup(String groupId) async {
    return BaseApiService.handleRequest(
      () => http.get(
        Uri.parse("$baseUrl/$groupId"), 
        headers: BaseApiService.headers
      ),
      (response) => BaseApiService.parseJsonList(response.body, RecurringEvent.fromJson),
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