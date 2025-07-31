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
  bool _filterActiveGroups = false;
  bool _isLoading = false;
  
  List<RecurringEvent> get currentGroupEvents => _currentGroupEvents; 
  bool get filterActiveGroups => _filterActiveGroups;
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

  /// Creates a new group/updates a group.
  Future<void> saveGroup(RecurringEventGroup groupData, bool isNewGroup) async {
    _setLoading(true);
    if (isNewGroup) {
      await RecurringEventGroupsApiService.createGroup(groupData);
      await loadGroups();
    }
    else {
      await RecurringEventGroupsApiService.updateGroup(groupData);
      await loadGroups();
    }
  }

  /// Returns recurring groups, filtering to only active groups if `filterActiveGroups` is true.
  List<RecurringEventGroup> get groups {
    return _groups.where((group) {
      return !(group.recurringEvents == 0 && !(group.isActive ?? false));
    }).toList();
  }

  /// Toggle whether to only display groups with active status.
  void toggleFilterActiveGroups() => _filterActiveGroups = !_filterActiveGroups;
  
  /// Set the loading value.
  void _setLoading(bool value) {
    _isLoading = value;
  }
}