// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recurring_event_group.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RecurringEventGroup _$RecurringEventGroupFromJson(Map<String, dynamic> json) =>
    RecurringEventGroup(
      name: json['name'] as String,
      id: json['id'] as String?,
      description: json['description'] as String?,
      color: const ColorConverter().fromJson((json['color'] as num).toInt()),
      isActive: json['is_active'] as bool?,
      startDate: _$JsonConverterFromJson<String, DateTime>(
        json['start_date'],
        const DatetimeConverter().fromJson,
      ),
      endDate: _$JsonConverterFromJson<String, DateTime>(
        json['end_date'],
        const DatetimeConverter().fromJson,
      ),
      recurringEvents: json['recurring_events'] as num?,
    );

Map<String, dynamic> _$RecurringEventGroupToJson(
  RecurringEventGroup instance,
) => <String, dynamic>{
  'name': instance.name,
  'id': instance.id,
  'description': instance.description,
  'color': const ColorConverter().toJson(instance.color),
  'is_active': instance.isActive,
  'start_date': _$JsonConverterToJson<String, DateTime>(
    instance.startDate,
    const DatetimeConverter().toJson,
  ),
  'end_date': _$JsonConverterToJson<String, DateTime>(
    instance.endDate,
    const DatetimeConverter().toJson,
  ),
  'recurring_events': instance.recurringEvents,
};

Value? _$JsonConverterFromJson<Json, Value>(
  Object? json,
  Value? Function(Json json) fromJson,
) => json == null ? null : fromJson(json as Json);

Json? _$JsonConverterToJson<Json, Value>(
  Value? value,
  Json? Function(Value value) toJson,
) => value == null ? null : toJson(value);
