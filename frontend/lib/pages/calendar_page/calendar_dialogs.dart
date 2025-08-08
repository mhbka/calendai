// lib/services/event_actions_service.dart
import 'package:flutter/material.dart';
import 'package:namer_app/constants.dart';
import 'package:namer_app/controllers/recurring_events_controller.dart';
import 'package:namer_app/models/calendar_event.dart';
import 'package:namer_app/controllers/calendar_controller.dart';
import 'package:namer_app/models/recurring_calendar_event.dart';
import 'package:namer_app/models/recurring_event_exception.dart';
import 'package:namer_app/utils/alerts.dart';
import 'package:namer_app/widgets/event_dialog.dart';
import 'package:namer_app/widgets/recurring_event_exception_dialog.dart';

class CalendarDialogs {
  static CalendarController _controller = CalendarController.instance;
  static RecurringEventsController _recurringController = RecurringEventsController.instance; 

  /// Show the dialog for confirming an event delete.
  static Future<bool> showDeleteConfirmation(BuildContext context, bool isRecurring) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Are you sure you want to delete this ${isRecurring ? "recurring event instance" : "event"}?"),
        content: Text(
          ' This action is irreversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: CalendarTheme.errorButtonStyle,
            child: Text('Delete'),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  /// Show the dialog options for an event.
  static Future<void> showEventOptions(
    BuildContext context,
    CalendarEvent event) async {
    await showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(Icons.edit),
            title: Text('Edit'),
            onTap: () async {
              Navigator.pop(context);
              await showDialog(
                context: context,
                builder: (context) => EventDialog(
                  event: event,
                  selectedDay: _controller.selectedDay
                ),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.delete, color: CalendarConstants.errorColor),
            title: Text(
              'Delete',
              style: CalendarConstants.errorTextStyle,
            ),
            onTap: () async {
              Navigator.pop(context);
              final confirmed = await showDeleteConfirmation(context, false);
              if (confirmed) {
                try {
                  await _controller.deleteEvent(event);
                  if (context.mounted) Alerts.showInfoDialog(context, "Success", "The event was successfully deleted.");
                } 
                catch (e) {
                  if (context.mounted) {
                    Alerts.showErrorDialog(context, "Error", "Failed to delete the event: $e. Please try again later.");
                  }
                  else {
                    print("context was not mounted");
                  }
                }
              }
            },
          ),
          ListTile(
            leading: Icon(Icons.cancel),
            title: Text('Cancel'),
            onTap: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  /// Show the dialog options for a recurring event.
  static Future<void> showRecurringEventOptions(
    BuildContext context,
    RecurringCalendarEvent event) async {
    await showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(Icons.edit),
            title: Text('Edit'),
            onTap: () async {
              Navigator.pop(context);
              await showDialog(
                context: context,
                builder: (context) => RecurringEventExceptionDialog(event: event),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.delete, color: CalendarConstants.errorColor),
            title: Text(
              'Delete',
              style: CalendarConstants.errorTextStyle,
            ),
            onTap: () async {
              Navigator.pop(context);
              final confirmed = await showDeleteConfirmation(context, true);
              if (confirmed) {
                try {
                  RecurringEventException exception = RecurringEventException(
                    id: event.exceptionId ?? '-1',
                    recurringEventId: event.recurringEventId,
                    exceptionDate: event.startTime,
                    exceptionType: RecurringEventExceptionType.cancelled
                  );
                  await _recurringController.saveEventException(exception, event.exceptionId == null);
                  if (context.mounted) {
                    Alerts.showInfoDialog(context, "Success", "The event was successfully deleted.");
                  }
                } 
                catch (e) {
                  if (context.mounted) {
                    Alerts.showErrorDialog(context, "Error", "Failed to delete the event: $e. Please try again later.");
                  }
                  else {
                    print("context was not mounted");
                  }
                }
              }
            },
          ),
          ListTile(
            leading: Icon(Icons.cancel),
            title: Text('Cancel'),
            onTap: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}