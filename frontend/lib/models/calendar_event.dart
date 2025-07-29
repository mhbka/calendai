import 'package:json_annotation/json_annotation.dart';
import 'package:namer_app/utils/datetime_converter.dart';
 
part 'calendar_event.g.dart';

/// Describes a singular calendar event.
@JsonSerializable()
class CalendarEvent {
  final String id;
  final String title;
  final String description;
  final String? location;

  @DatetimeConverter()
  final DateTime startTime;
  @DatetimeConverter()
  final DateTime endTime;

  CalendarEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.startTime,
    required this.endTime,
    this.location,
  });

  CalendarEvent copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? startTime,
    DateTime? endTime,
    String? location,
  }) {
    return CalendarEvent(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      location: location ?? this.location,
    );
  }

  factory CalendarEvent.fromJson(Map<String, dynamic> json) => _$CalendarEventFromJson(json);
  Map<String, dynamic> toJson() => _$CalendarEventToJson(this);
}