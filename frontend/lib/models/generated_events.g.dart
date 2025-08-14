// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'generated_events.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GeneratedEvents _$GeneratedEventsFromJson(Map<String, dynamic> json) =>
    GeneratedEvents(
      events: (json['events'] as List<dynamic>)
          .map((e) => CalendarEvent.fromJson(e as Map<String, dynamic>))
          .toList(),
      recurringEvents: (json['recurring_events'] as List<dynamic>)
          .map((e) => RecurringEvent.fromJson(e as Map<String, dynamic>))
          .toList(),
      recurringEventGroup: json['recurring_event_group'] == null
          ? null
          : RecurringEventGroup.fromJson(
              json['recurring_event_group'] as Map<String, dynamic>,
            ),
    );

Map<String, dynamic> _$GeneratedEventsToJson(GeneratedEvents instance) =>
    <String, dynamic>{
      'events': instance.events,
      'recurring_events': instance.recurringEvents,
      'recurring_event_group': instance.recurringEventGroup,
    };
