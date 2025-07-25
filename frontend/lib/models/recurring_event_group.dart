import 'dart:ui';
import 'package:json_annotation/json_annotation.dart';
import 'package:namer_app/utils/color_converter.dart';

part 'recurring_event_group.g.dart';

/// Describes a recurring event group.
@JsonSerializable()
class RecurringEventGroup {
  final String name;
  final String id;
  final String? description;

  @ColorConverter()
  final Color color;

  final bool? isActive;
  final DateTime? startDate;
  final DateTime? endDate;
  final num recurringEvents;

  RecurringEventGroup({
    required this.name,
    required this.id,
    this.description,
    required this.color,
    required this.isActive,
    this.startDate,
    this.endDate,
    required this.recurringEvents,
  });

  factory RecurringEventGroup.fromJson(Map<String, dynamic> json) => _$RecurringEventGroupFromJson(json);
  Map<String, dynamic> toJson() => _$RecurringEventGroupToJson(this);
}