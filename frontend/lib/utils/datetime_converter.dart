import 'package:json_annotation/json_annotation.dart';

/// Used for (de)serializing a DateTime from/to JSON,
/// using local time in-app and UTC time externally.
class DatetimeConverter implements JsonConverter<DateTime, String> {
  const DatetimeConverter();

  @override
  DateTime fromJson(String json) {
    return DateTime.parse(json).toLocal();
  }

  @override
  String toJson(DateTime object) {
    return object.toUtc().toIso8601String();
  }
}