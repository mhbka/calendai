import 'package:flutter/material.dart';
import 'package:namer_app/models/recurring_event.dart';
import 'package:namer_app/models/recurring_event_group.dart';
import 'package:namer_app/services/recurring_event_groups_api_service.dart';

///
class RecurringEventGroupsController extends ChangeNotifier {
  // singleton stuff
  RecurringEventGroupsController._internal() {
    loadGroups();
  }

  static final RecurringEventGroupsController _instance = RecurringEventGroupsController._internal();

  factory RecurringEventGroupsController() {
    return _instance;
  }

  static RecurringEventGroupsController get instance => _instance;

  // members
  List<RecurringEventGroup> _groups = [];
  List<RecurringEvent> _currentGroupEvents = [];
  bool _isLoading = false;

  List<RecurringEventGroup> get groups => _groups;
  List<RecurringEvent> get currentGroupEvents => _currentGroupEvents; 
  bool get isLoading => _isLoading;

  // methods
  /// Loads all recurring event groups.
  Future<void> loadGroups() async {
    _setLoading(true);
    _groups =  await RecurringEventGroupsApiService.fetchAllGroups();
  }

  /// Loads the chosen group's events.
  Future<void> loadEventsForGroup(String groupId) async {
    _setLoading(true);
    _currentGroupEvents = await RecurringEventGroupsApiService.fetchEventsForGroup(groupId);
  }
  
  void _setLoading(bool value) {
    _isLoading = value;
  }
}