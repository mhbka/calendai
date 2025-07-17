import 'package:json_annotation/json_annotation.dart';

part 'recurring_event.g.dart';

/// Describes a calendar event which can recur.
@JsonSerializable()
class RecurringEvent {
  final String name;
  final String id;

  RecurringEvent({
    required this.name,
    required this.id
  });

  factory RecurringEvent.fromJson(Map<String, dynamic> json) => _$RecurringEventFromJson(json);
  Map<String, dynamic> toJson() => _$RecurringEventToJson(this);
}