import 'package:json_annotation/json_annotation.dart';
import 'package:calendai/models/calendar_event.dart';
import 'package:calendai/models/recurring_event.dart';
import 'package:calendai/models/recurring_event_group.dart';

part 'generated_events.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class GeneratedEvents { 
  List<CalendarEvent> events;
  List<RecurringEvent> recurringEvents;
  RecurringEventGroup? recurringEventGroup;

  GeneratedEvents({
    required this.events,
    required this.recurringEvents,
    this.recurringEventGroup
  });

  factory GeneratedEvents.fromJson(Map<String, dynamic> json) => _$GeneratedEventsFromJson(json);
  Map<String, dynamic> toJson() => _$GeneratedEventsToJson(this);
}