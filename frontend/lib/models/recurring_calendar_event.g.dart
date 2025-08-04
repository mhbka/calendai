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
  startTime: const DatetimeConverter().fromJson(json['startTime'] as String),
  endTime: const DatetimeConverter().fromJson(json['endTime'] as String),
  recurringEventId: json['recurringEventId'] as String,
  exceptionId: json['exceptionId'] as String?,
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
  'startTime': const DatetimeConverter().toJson(instance.startTime),
  'endTime': const DatetimeConverter().toJson(instance.endTime),
  'recurringEventId': instance.recurringEventId,
  'exceptionId': instance.exceptionId,
  'group': instance.group,
};
