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
  
  // Messages
  static const String eventAddedMessage = 'Event added';
  static const String eventUpdatedMessage = 'Event updated';
  static const String eventDeletedMessage = 'Event deleted';
  static const String failedToSaveMessage = 'Failed to save event';
  static const String failedToDeleteMessage = 'Failed to delete event';
  static const String failedToLoadMessage = 'Failed to load events';
  static const String deleteConfirmationTitle = 'Delete Event';
  static const String deleteConfirmationMessage = 'Are you sure you want to delete';
  static const String todaysEventsTitle = "Today's events";
  
  // Button Labels
  static const String addWithAILabel = 'Add with AI';
  static const String addEventLabel = 'Add Event';
  static const String editEventLabel = 'Edit Event';
  static const String deleteEventLabel = 'Delete Event';
  static const String cancelLabel = 'Cancel';
  static const String deleteLabel = 'Delete';
  static const String logoutLabel = 'Log out';
  static const String refreshLabel = 'Refresh';
  static const String viewRecurringEventsLabel = 'View recurring events';
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