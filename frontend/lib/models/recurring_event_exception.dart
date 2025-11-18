import 'package:json_annotation/json_annotation.dart';
import 'package:calendai/utils/datetime_converter.dart';

part 'recurring_event_exception.g.dart';

/// An exception to a recurring event.
@JsonSerializable(fieldRename: FieldRename.snake)
class RecurringEventException {
  final String id;
  final String recurringEventId;
  
  @DatetimeConverter()
  final DateTime exceptionDate;
  
  final RecurringEventExceptionType exceptionType;
  final String? modifiedTitle;
  final String? modifiedDescription;
  final String? modifiedLocation;
  
  @DatetimeConverter()
  final DateTime? modifiedStartTime;
  @DatetimeConverter()
  final DateTime? modifiedEndTime;

  RecurringEventException({
    required this.id,
    required this.recurringEventId,
    required this.exceptionDate,
    required this.exceptionType,
    this.modifiedTitle,
    this.modifiedDescription,
    this.modifiedLocation,
    this.modifiedStartTime,
    this.modifiedEndTime,
  });

  factory RecurringEventException.fromJson(Map<String, dynamic> json) => 
      _$RecurringEventExceptionFromJson(json);
  
  Map<String, dynamic> toJson() => _$RecurringEventExceptionToJson(this);
}

/// The type of recurring event exception.
@JsonEnum(valueField: 'value')
enum RecurringEventExceptionType {
  cancelled('cancelled'),
  modified('modified');

  const RecurringEventExceptionType(this.value);
  final String value;

  @override
  String toString() => value;
}