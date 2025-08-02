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

  /// Returns recurring groups, filtering to only active groups if `filterActiveGroups` is true.
  List<RecurringEventGroup> get groups {
    print(_groups.length);
    var groups = _groups.where((group) {
      if (filterActiveGroups) {
        return group.isActive ?? true;
      } else {
        return true;
      }
    }).toList();
     
    // Deal with the "Ungrouped" group case, which aggregates all events without groups 
    if (groups.isEmpty) {
      groups.add(RecurringEventGroup(
        name: "Ungrouped", 
        id: "-1", 
        description: "Contains all events without a group.",
        color: Colors.white, 
        isActive: true, 
        recurringEvents: 0
        )
      );
    }
    else {
      groups.sort((a, b) {
        if (a.name == "Ungrouped") {
          return 100000;
        } else {
          return a.name.compareTo(b.name);
        } 
      });
    }
    return groups;
  }
  
  /// Loads all recurring event groups.
  Future<void> loadGroups() async {
    _setLoading(true);
    _groups =  await RecurringEventGroupsApiService.fetchAllGroups();
    notifyListeners();
    _setLoading(false);
  }

  /// Creates a new group/updates a group.
  Future<void> saveGroup(RecurringEventGroup groupData, bool isNewGroup) async {
    _setLoading(true);
    try {
      if (isNewGroup) {
        await RecurringEventGroupsApiService.createGroup(groupData);
      }
      else {
        await RecurringEventGroupsApiService.updateGroup(groupData);
      }
    }
    catch (e) {
      rethrow;
    }
    finally {
      await loadGroups();
      _setLoading(false);
    }
  }

  /// Delete a group.
  Future<void> deleteGroup(String groupId) async {
    _setLoading(true);
    try {
      await RecurringEventGroupsApiService.deleteGroup(groupId);
    }
    catch (e) {
      rethrow;
    }
    finally {
      await loadGroups();
      _setLoading(false);
    }
  }

  /// Toggle whether to only display groups with active status.
  void toggleFilterActiveGroups() => _filterActiveGroups = !_filterActiveGroups;
  
  /// Set the loading value.
  void _setLoading(bool value) {
    _isLoading = value;
  }
}