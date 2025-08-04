import 'package:json_annotation/json_annotation.dart';
import 'package:namer_app/models/calendar_event.dart';
import 'package:namer_app/models/recurring_event_group.dart';
import 'package:namer_app/utils/datetime_converter.dart';

part 'recurring_calendar_event.g.dart';

@JsonSerializable()
class RecurringCalendarEvent {
  // Event metadata
  final String title;
  final String? description;
  final String? location;
  
  @DatetimeConverter()
  final DateTime startTime;
  
  @DatetimeConverter()
  final DateTime endTime;

  // Recurrence metadata
  final String recurringEventId;
  final String? exceptionId;
  
  final RecurringEventGroup? group;

  RecurringCalendarEvent({
    required this.title,
    this.description,
    this.location,
    required this.startTime,
    required this.endTime,
    required this.recurringEventId,
    this.exceptionId,
    this.group,
  });

  /// Converts to a `CalendarEvent`, mostly for displaying in the calendar.
  CalendarEvent recurringToCalendarEvent() {
  return CalendarEvent(
    id: exceptionId ?? '${recurringEventId}_${startTime.millisecondsSinceEpoch}',
    title: title,
    description: description,
    location: location,
    startTime: startTime,
    endTime: endTime,
  );
}

  // TODO: do I need this fn
  /*
  RecurringCalendarEvent copyWith({
    String? title,
    String? description,
    String? location,
    DateTime? startTime,
    DateTime? endTime,
    String? recurringEventId,
    String? exceptionId,
    RecurringEventGroup? group,
  }) {
    return RecurringCalendarEvent(
      title: title ?? this.title,
      description: description ?? this.description,
      location: location ?? this.location,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      recurringEventId: recurringEventId ?? this.recurringEventId,
      exceptionId: exceptionId ?? this.exceptionId,
      group: group ?? this.group,
    );
  }
  */

  factory RecurringCalendarEvent.fromJson(Map<String, dynamic> json) =>
      _$RecurringCalendarEventFromJson(json);

  Map<String, dynamic> toJson() => _$RecurringCalendarEventToJson(this);
}