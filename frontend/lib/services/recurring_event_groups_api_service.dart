import 'package:namer_app/main.dart';
import 'package:namer_app/models/recurring_event.dart';
import 'package:namer_app/models/recurring_event_group.dart';

class RecurringEventGroupsApiService {
  static String baseUrl = "${envVars['api_base_url']!}/recurring_event_groups";

  /// Fetch all recurring event groups for a user.
  /// TODO: Stub implementation
  static Future<List<RecurringEventGroup>> fetchAllGroups() async {

  }

  /// Fetch recurring events under a group.
  /// TODO: Stub implementation
  static Future<List<RecurringEvent>> fetchEventsForGroup(String groupId) async {

  }
} 