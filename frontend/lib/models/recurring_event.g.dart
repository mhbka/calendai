// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recurring_event.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RecurringEvent _$RecurringEventFromJson(Map<String, dynamic> json) =>
    RecurringEvent(
      id: json['id'] as String,
      groupId: json['groupId'] as String?,
      userId: json['userId'] as String,
      isActive: json['isActive'] as bool,
      title: json['title'] as String,
      description: json['description'] as String?,
      location: json['location'] as String?,
      eventDurationSeconds: (json['eventDurationSeconds'] as num).toInt(),
      recurrenceStart: DateTime.parse(json['recurrenceStart'] as String),
      recurrenceEnd: json['recurrenceEnd'] == null
          ? null
          : DateTime.parse(json['recurrenceEnd'] as String),
      rrule: json['rrule'] as String,
    );

Map<String, dynamic> _$RecurringEventToJson(RecurringEvent instance) =>
    <String, dynamic>{
      'id': instance.id,
      'groupId': instance.groupId,
      'userId': instance.userId,
      'isActive': instance.isActive,
      'title': instance.title,
      'description': instance.description,
      'location': instance.location,
      'eventDurationSeconds': instance.eventDurationSeconds,
      'recurrenceStart': instance.recurrenceStart.toIso8601String(),
      'recurrenceEnd': instance.recurrenceEnd?.toIso8601String(),
      'rrule': instance.rrule,
    };
