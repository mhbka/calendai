import 'dart:ui';

import 'package:namer_app/models/recurring_event.dart';

/// Describes a recurring event group.
class RecurringEventGroup {
  final String name;
  final String? description;
  final Color color;
  final bool isActive;
  final DateTime? startDate;
  final DateTime? endDate;
  final List<RecurringEvent> recurringEvents;

  RecurringEventGroup({
    required this.name,
    this.description,
    required this.color,
    required this.isActive,
    this.startDate,
    this.endDate,
    required this.recurringEvents,
  });
}