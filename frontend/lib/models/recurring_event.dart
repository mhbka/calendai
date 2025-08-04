import 'package:json_annotation/json_annotation.dart';
import 'package:namer_app/utils/datetime_converter.dart';

part 'recurring_event.g.dart';

/// Describes a calendar event which can recur.
@JsonSerializable()
class RecurringEvent {
  final String id;
  final String? groupId;
  final bool isActive;
  final String title;
  final String? description;
  final String? location;
  final int eventDurationSeconds;
  
  @DatetimeConverter()
  final DateTime recurrenceStart;

  @DatetimeConverter()
  final DateTime? recurrenceEnd;
  final String rrule;

  RecurringEvent({
    required this.id,
    this.groupId,
    required this.isActive,
    required this.title,
    this.description,
    this.location,
    required this.eventDurationSeconds,
    required this.recurrenceStart,
    this.recurrenceEnd,
    required this.rrule,
  });

  factory RecurringEvent.fromJson(Map<String, dynamic> json) => _$RecurringEventFromJson(json);
  Map<String, dynamic> toJson() => _$RecurringEventToJson(this);
}