// lib/services/event_actions_service.dart
import 'package:flutter/material.dart';
import 'package:namer_app/constants.dart';
import 'package:namer_app/models/calendar_event.dart';
import 'package:namer_app/controllers/calendar_controller.dart';

class CalendarDialogs {
  final CalendarController controller;

  CalendarDialogs({required this.controller});

  /// Save an event.
  Future<void> saveEvent(
    BuildContext context, {
    CalendarEvent? existingEvent,
    required String title,
    required String description,
    String? location,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    try {
      await controller.saveEvent(
        existingEvent: existingEvent,
        title: title,
        description: description,
        location: location,
        startTime: startTime,
        endTime: endTime,
      );
      _showSuccessMessage(
        context,
        existingEvent != null
            ? CalendarConstants.eventUpdatedMessage
            : CalendarConstants.eventAddedMessage,
      );
      Navigator.pop(context);
    } catch (e) {
      _showErrorMessage(context, '${CalendarConstants.failedToSaveMessage}: $e');
    }
  }

  /// Delete an event.
  Future<void> deleteEvent(BuildContext context, CalendarEvent event) async {
    try {
      await controller.deleteEvent(event);
      if (context.mounted) _showSuccessMessage(context, CalendarConstants.eventDeletedMessage);
    } catch (e) {
      if (context.mounted) {
        _showErrorMessage(context, '${CalendarConstants.failedToDeleteMessage}: $e');
      }
      else {
        print("context was not mounted");
      }
    }
  }

  /// Show the dialog for confirming an event delete.
  Future<bool> showDeleteConfirmation(
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

  /// Show the options for an event.
  Future<void> showEventOptions(
    BuildContext context,
    CalendarEvent event, {
    required VoidCallback onEdit,
  }) async {
    await showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(Icons.edit),
            title: Text(CalendarConstants.editEventLabel),
            onTap: () {
              Navigator.pop(context);
              onEdit();
            },
          ),
          ListTile(
            leading: Icon(Icons.delete, color: CalendarConstants.errorColor),
            title: Text(
              CalendarConstants.deleteEventLabel,
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
  
  void showSnackBar(BuildContext context, Widget content) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: content),
    );
  }

  void _showSuccessMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _showErrorMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }
}