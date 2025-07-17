// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recurring_event_group.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RecurringEventGroup _$RecurringEventGroupFromJson(Map<String, dynamic> json) =>
    RecurringEventGroup(
      name: json['name'] as String,
      id: json['id'] as String,
      description: json['description'] as String?,
      color: const ColorConverter().fromJson((json['color'] as num).toInt()),
      isActive: json['isActive'] as bool,
      startDate: json['startDate'] == null
          ? null
          : DateTime.parse(json['startDate'] as String),
      endDate: json['endDate'] == null
          ? null
          : DateTime.parse(json['endDate'] as String),
      recurringEvents: json['recurringEvents'] as num,
    );

Map<String, dynamic> _$RecurringEventGroupToJson(
  RecurringEventGroup instance,
) => <String, dynamic>{
  'name': instance.name,
  'id': instance.id,
  'description': instance.description,
  'color': const ColorConverter().toJson(instance.color),
  'isActive': instance.isActive,
  'startDate': instance.startDate?.toIso8601String(),
  'endDate': instance.endDate?.toIso8601String(),
  'recurringEvents': instance.recurringEvents,
};
