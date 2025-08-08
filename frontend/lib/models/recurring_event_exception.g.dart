// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recurring_event_exception.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RecurringEventException _$RecurringEventExceptionFromJson(
  Map<String, dynamic> json,
) => RecurringEventException(
  id: json['id'] as String,
  recurringEventId: json['recurring_event_id'] as String,
  exceptionDate: const DatetimeConverter().fromJson(
    json['exception_date'] as String,
  ),
  exceptionType: $enumDecode(
    _$RecurringEventExceptionTypeEnumMap,
    json['exception_type'],
  ),
  modifiedTitle: json['modified_title'] as String?,
  modifiedDescription: json['modified_description'] as String?,
  modifiedLocation: json['modified_location'] as String?,
  modifiedStartTime: _$JsonConverterFromJson<String, DateTime>(
    json['modified_start_time'],
    const DatetimeConverter().fromJson,
  ),
  modifiedEndTime: _$JsonConverterFromJson<String, DateTime>(
    json['modified_end_time'],
    const DatetimeConverter().fromJson,
  ),
);

Map<String, dynamic> _$RecurringEventExceptionToJson(
  RecurringEventException instance,
) => <String, dynamic>{
  'id': instance.id,
  'recurring_event_id': instance.recurringEventId,
  'exception_date': const DatetimeConverter().toJson(instance.exceptionDate),
  'exception_type':
      _$RecurringEventExceptionTypeEnumMap[instance.exceptionType]!,
  'modified_title': instance.modifiedTitle,
  'modified_description': instance.modifiedDescription,
  'modified_location': instance.modifiedLocation,
  'modified_start_time': _$JsonConverterToJson<String, DateTime>(
    instance.modifiedStartTime,
    const DatetimeConverter().toJson,
  ),
  'modified_end_time': _$JsonConverterToJson<String, DateTime>(
    instance.modifiedEndTime,
    const DatetimeConverter().toJson,
  ),
};

const _$RecurringEventExceptionTypeEnumMap = {
  RecurringEventExceptionType.cancelled: 'cancelled',
  RecurringEventExceptionType.modified: 'modified',
};

Value? _$JsonConverterFromJson<Json, Value>(
  Object? json,
  Value? Function(Json json) fromJson,
) => json == null ? null : fromJson(json as Json);

Json? _$JsonConverterToJson<Json, Value>(
  Value? value,
  Json? Function(Value value) toJson,
) => value == null ? null : toJson(value);
