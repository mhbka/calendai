// lib/constants/calendar_constants.dart
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class CalendarConstants {
  // Colors
  static const Color primaryColor = Colors.deepPurple;
  static const Color errorColor = Colors.red;
  static const Color backgroundColor = Colors.white;
  
  // Padding and Spacing
  static const EdgeInsets defaultPadding = EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0);
  static const EdgeInsets floatingButtonPadding = EdgeInsets.only(top: 0);
  static const double defaultSpacing = 8.0;
  static const double buttonSpacing = 16.0;
  
  // Calendar Configuration
  static const int firstYear = 2020;
  static const int lastYear = 2030;
  static const StartingDayOfWeek startingDayOfWeek = StartingDayOfWeek.monday;
  
  // Text Styles
  static const TextStyle whiteTextStyle = TextStyle(color: Colors.white);
  static const TextStyle errorTextStyle = TextStyle(color: Colors.red);
}

class CalendarTheme {
  static CalendarStyle get calendarStyle => CalendarStyle(
    outsideDaysVisible: false,
  );
  
  static ButtonStyle get primaryButtonStyle => TextButton.styleFrom(
    backgroundColor: CalendarConstants.primaryColor,
  );
  
  static ButtonStyle get errorButtonStyle => ElevatedButton.styleFrom(
    backgroundColor: CalendarConstants.errorColor,
  );
}