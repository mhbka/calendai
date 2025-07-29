// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'calendar_event.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CalendarEvent _$CalendarEventFromJson(Map<String, dynamic> json) =>
    CalendarEvent(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      startTime: const DatetimeConverter().fromJson(
        json['startTime'] as String,
      ),
      endTime: const DatetimeConverter().fromJson(json['endTime'] as String),
      location: json['location'] as String?,
    );

Map<String, dynamic> _$CalendarEventToJson(CalendarEvent instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'location': instance.location,
      'startTime': const DatetimeConverter().toJson(instance.startTime),
      'endTime': const DatetimeConverter().toJson(instance.endTime),
    };
