import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:namer_app/main.dart';
import 'package:namer_app/models/recurring_event.dart';
import 'package:namer_app/models/recurring_event_group.dart';
import 'package:namer_app/services/service_exception.dart';

/// For interacting with the recurring event groups' API.
class RecurringEventGroupsApiService {
  static String baseUrl = "${envVars['api_base_url']!}/recurring_event_groups";

  static Map<String, String> _headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    // 'Authorization': 'Bearer ${AuthService.getToken()}',
  };

  /// Fetch all recurring event groups for a user.
  static Future<List<RecurringEventGroup>> fetchAllGroups() async {
    try {
      final response = await http.get(
        Uri.parse(baseUrl), 
        headers: _headers
      );
      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        return jsonData.map((json) => RecurringEventGroup.fromJson(json));
      }
      else {
        throw ServiceException('Experienced a network error', response.statusCode);
      }
    }
    catch(e) {
      if (e is ServiceException) rethrow;
      throw ServiceException("Experienced an unexpected error: ${e.toString()}", -1);
    }
  }

  /// Fetch recurring events under a group.
  static Future<List<RecurringEvent>> fetchEventsForGroup(String groupId) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/$groupId"), 
        headers: _headers
      );
      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        return jsonData.map((json) => RecurringEvent.fromJson(json));
      }
      else {
        throw ServiceException('Experienced a network error', response.statusCode);
      }
    }
    catch(e) {
      if (e is ServiceException) rethrow;
      throw ServiceException("Experienced an unexpected error: ${e.toString()}", -1);
    }
  }
} 