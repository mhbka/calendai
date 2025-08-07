// lib/services/event_actions_service.dart
import 'package:flutter/material.dart';
import 'package:namer_app/constants.dart';
import 'package:namer_app/models/calendar_event.dart';
import 'package:namer_app/controllers/calendar_controller.dart';
import 'package:namer_app/models/recurring_calendar_event.dart';
import 'package:namer_app/utils/alerts.dart';
import 'package:namer_app/widgets/event_dialog.dart';

class CalendarDialogs {
  static CalendarController _controller = CalendarController.instance;

  /// Delete an event.
  static Future<void> deleteEvent(BuildContext context, CalendarEvent event) async {
    try {
      await _controller.deleteEvent(event);
      if (context.mounted) Alerts.showInfoDialog(context, "Success", "The event was successfully deleted.");
    } catch (e) {
      if (context.mounted) {
        Alerts.showErrorDialog(context, "Error", "Failed to delete the event: $e. Please try again later.");
      }
      else {
        print("context was not mounted");
      }
    }
  }

  /// Show the dialog for confirming an event delete.
  static Future<bool> showDeleteConfirmation(
    BuildContext context,
    CalendarEvent event,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(CalendarConstants.deleteConfirmationTitle),
        content: Text(
          '${CalendarConstants.deleteConfirmationMessage} "${event.title}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(CalendarConstants.cancelLabel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: CalendarTheme.errorButtonStyle,
            child: Text(CalendarConstants.deleteLabel),
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
              final confirmed = await showDeleteConfirmation(context, event);
              if (confirmed) {
                await deleteEvent(context, event);
              }
            },
          ),
          ListTile(
            leading: Icon(Icons.cancel),
            title: Text(CalendarConstants.cancelLabel),
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
            onTap: () {
              Navigator.pop(context);
              // TODO: modify RecurringEventDialog to handle 'modify exceptions'
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
              // TODO: create a delete exception dialog
            },
          ),
          ListTile(
            leading: Icon(Icons.cancel),
            title: Text(CalendarConstants.cancelLabel),
            onTap: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}