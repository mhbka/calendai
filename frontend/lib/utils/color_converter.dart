import 'dart:ui';
import 'package:json_annotation/json_annotation.dart';

/// Used for (de)serializing a Color to/from JSON.
class ColorConverter implements JsonConverter<Color, int> {
  const ColorConverter();

  @override
  Color fromJson(int json) => Color(json);

  @override
  int toJson(Color object) => object.toARGB32();
}