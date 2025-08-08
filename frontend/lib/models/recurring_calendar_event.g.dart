// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recurring_calendar_event.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RecurringCalendarEvent _$RecurringCalendarEventFromJson(
  Map<String, dynamic> json,
) => RecurringCalendarEvent(
  title: json['title'] as String,
  description: json['description'] as String?,
  location: json['location'] as String?,
  startTime: const DatetimeConverter().fromJson(json['start_time'] as String),
  endTime: const DatetimeConverter().fromJson(json['end_time'] as String),
  recurringEventId: json['recurring_event_id'] as String,
  exceptionId: json['exception_id'] as String?,
  group: json['group'] == null
      ? null
      : RecurringEventGroup.fromJson(json['group'] as Map<String, dynamic>),
);

Map<String, dynamic> _$RecurringCalendarEventToJson(
  RecurringCalendarEvent instance,
) => <String, dynamic>{
  'title': instance.title,
  'description': instance.description,
  'location': instance.location,
  'start_time': const DatetimeConverter().toJson(instance.startTime),
  'end_time': const DatetimeConverter().toJson(instance.endTime),
  'recurring_event_id': instance.recurringEventId,
  'exception_id': instance.exceptionId,
  'group': instance.group,
};
