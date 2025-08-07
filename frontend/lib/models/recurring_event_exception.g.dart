// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recurring_event_exception.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RecurringEventException _$RecurringEventExceptionFromJson(
  Map<String, dynamic> json,
) => RecurringEventException(
  id: json['id'] as String,
  recurringEventId: json['recurringEventId'] as String,
  exceptionDate: const DatetimeConverter().fromJson(
    json['exceptionDate'] as String,
  ),
  exceptionType: $enumDecode(
    _$RecurringEventExceptionTypeEnumMap,
    json['exceptionType'],
  ),
  modifiedTitle: json['modifiedTitle'] as String?,
  modifiedDescription: json['modifiedDescription'] as String?,
  modifiedLocation: json['modifiedLocation'] as String?,
  modifiedStartTime: _$JsonConverterFromJson<String, DateTime>(
    json['modifiedStartTime'],
    const DatetimeConverter().fromJson,
  ),
  modifiedEndTime: _$JsonConverterFromJson<String, DateTime>(
    json['modifiedEndTime'],
    const DatetimeConverter().fromJson,
  ),
);

Map<String, dynamic> _$RecurringEventExceptionToJson(
  RecurringEventException instance,
) => <String, dynamic>{
  'id': instance.id,
  'recurringEventId': instance.recurringEventId,
  'exceptionDate': const DatetimeConverter().toJson(instance.exceptionDate),
  'exceptionType':
      _$RecurringEventExceptionTypeEnumMap[instance.exceptionType]!,
  'modifiedTitle': instance.modifiedTitle,
  'modifiedDescription': instance.modifiedDescription,
  'modifiedLocation': instance.modifiedLocation,
  'modifiedStartTime': _$JsonConverterToJson<String, DateTime>(
    instance.modifiedStartTime,
    const DatetimeConverter().toJson,
  ),
  'modifiedEndTime': _$JsonConverterToJson<String, DateTime>(
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
