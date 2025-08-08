// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recurring_event.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RecurringEvent _$RecurringEventFromJson(Map<String, dynamic> json) =>
    RecurringEvent(
      id: json['id'] as String,
      groupId: json['group_id'] as String?,
      isActive: json['is_active'] as bool,
      title: json['title'] as String,
      description: json['description'] as String?,
      location: json['location'] as String?,
      eventDurationSeconds: (json['event_duration_seconds'] as num).toInt(),
      recurrenceStart: const DatetimeConverter().fromJson(
        json['recurrence_start'] as String,
      ),
      recurrenceEnd: _$JsonConverterFromJson<String, DateTime>(
        json['recurrence_end'],
        const DatetimeConverter().fromJson,
      ),
      rrule: json['rrule'] as String,
    );

Map<String, dynamic> _$RecurringEventToJson(RecurringEvent instance) =>
    <String, dynamic>{
      'id': instance.id,
      'group_id': instance.groupId,
      'is_active': instance.isActive,
      'title': instance.title,
      'description': instance.description,
      'location': instance.location,
      'event_duration_seconds': instance.eventDurationSeconds,
      'recurrence_start': const DatetimeConverter().toJson(
        instance.recurrenceStart,
      ),
      'recurrence_end': _$JsonConverterToJson<String, DateTime>(
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
