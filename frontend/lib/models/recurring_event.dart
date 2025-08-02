import 'package:json_annotation/json_annotation.dart';

part 'recurring_event.g.dart';

/// Describes a calendar event which can recur.
@JsonSerializable()
class RecurringEvent {
  final String id;
  final String? groupId;
  final String userId;
  final bool isActive;
  final String title;
  final String? description;
  final String? location;
  final int eventDurationSeconds;
  final DateTime recurrenceStart;
  final DateTime? recurrenceEnd;
  final String rrule;

  RecurringEvent({
    required this.id,
    this.groupId,
    required this.userId,
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