import 'package:flutter/material.dart';
import 'package:namer_app/models/recurring_event.dart';
import 'package:namer_app/models/recurring_event_group.dart';
import 'package:namer_app/services/recurring_event_groups_api_service.dart';
import 'package:namer_app/services/recurring_events_api_service.dart';

/// Controller for recurring events under a group.
class RecurringEventsController extends ChangeNotifier {
  // singleton stuff
  RecurringEventsController._internal() {
    loadEvents();
  }

  static final RecurringEventsController _instance = RecurringEventsController._internal();

  factory RecurringEventsController() {
    return _instance;
  }

  static RecurringEventsController get instance => _instance;

  // members
  String? _currentGroupId;
  RecurringEventGroup? _currentGroup;
  List<RecurringEvent> _events = [];
  bool _filterActiveEvents = false;
  bool _isLoading = false;
  
  RecurringEventGroup? get currentGroup => _currentGroup; 
  bool get filterActiveEvents => _filterActiveEvents;
  bool get isLoading => _isLoading;

  // methods

  /// Returns recurring groups, filtering to only active groups if `filterActiveEvents` is true.
  List<RecurringEvent> get events {
    return _events.where((event) {
      if (filterActiveEvents) {
        return event.isActive;
      } else {
        return true;
      }
    }).toList();
  }

  /// Sets the current group.
  Future<void> setGroup(String? groupId) async {
    _currentGroupId = groupId;
    if (groupId != null) {
      _currentGroup = await RecurringEventGroupsApiService.fetchGroup(groupId);
    } else {
      _currentGroup = null;
    }
    await loadEvents();
  }
  
  /// Loads all events under the current group.
  Future<void> loadEvents() async {
    _setLoading(true);
    _events = await RecurringEventsApiService.fetchEvents(_currentGroupId);
    notifyListeners();
    _setLoading(false);
  }

  /// Creates a new event/updates a event.
  Future<void> saveEvent(RecurringEvent event, bool isNewGroup) async {
    _setLoading(true);
    try {
      if (isNewGroup) {
        await RecurringEventsApiService.createEvent(event, currentGroup?.id);
      }
      else {
        await RecurringEventsApiService.updateEvent(event);
      }
    }
    catch (e) {
      rethrow;
    }
    finally {
      await loadEvents();
      _setLoading(false);
    }
  }

  /// Delete a event.
  Future<void> deleteGroup(String eventId) async {
    _setLoading(true);
    try {
      await RecurringEventsApiService.deleteEvent(eventId);
    }
    catch (e) {
      rethrow;
    }
    finally {
      await loadEvents();
      _setLoading(false);
    }
  }

  /// Toggle whether to only display events with active status.
  void toggleFilterActiveEvents() => _filterActiveEvents = !_filterActiveEvents;
  
  /// Set the loading value.
  void _setLoading(bool value) {
    _isLoading = value;
  }
}