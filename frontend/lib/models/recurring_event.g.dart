// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recurring_event.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RecurringEvent _$RecurringEventFromJson(Map<String, dynamic> json) =>
    RecurringEvent(
      id: json['id'] as String,
      groupId: json['groupId'] as String?,
      isActive: json['isActive'] as bool,
      title: json['title'] as String,
      description: json['description'] as String?,
      location: json['location'] as String?,
      eventDurationSeconds: (json['eventDurationSeconds'] as num).toInt(),
      recurrenceStart: const DatetimeConverter().fromJson(
        json['recurrenceStart'] as String,
      ),
      recurrenceEnd: _$JsonConverterFromJson<String, DateTime>(
        json['recurrenceEnd'],
        const DatetimeConverter().fromJson,
      ),
      rrule: json['rrule'] as String,
    );

Map<String, dynamic> _$RecurringEventToJson(
  RecurringEvent instance,
) => <String, dynamic>{
  'id': instance.id,
  'groupId': instance.groupId,
  'isActive': instance.isActive,
  'title': instance.title,
  'description': instance.description,
  'location': instance.location,
  'eventDurationSeconds': instance.eventDurationSeconds,
  'recurrenceStart': const DatetimeConverter().toJson(instance.recurrenceStart),
  'recurrenceEnd': _$JsonConverterToJson<String, DateTime>(
    instance.recurrenceEnd,
    const DatetimeConverter().toJson,
  ),
  'rrule': instance.rrule,
};

Value? _$JsonConverterFromJson<Json, Value>(
  Object? json,
  Value? Function(Json json) fromJson,
) => json == null ? null : fromJson(json as Json);

Json? _$JsonConverterToJson<Json, Value>(
  Value? value,
  Json? Function(Value value) toJson,
) => value == null ? null : toJson(value);
