import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:namer_app/services/outlook_calendar_api_service.dart';
import 'package:namer_app/utils/alerts.dart';


/// Builds the list of AppBar actions for the calendar page.
List<Widget> buildCalendarAppbarActions(
  BuildContext context, 
  VoidCallback handleRefresh,
  VoidCallback handleLogout
  ) {
  return [
      IconButton(
        icon: Icon(Icons.refresh),
        onPressed: handleRefresh,
      ),
      TextButton(
        onPressed: () => context.push('/recurring_event_groups'),
        style: TextButton.styleFrom(
          backgroundColor: Colors.deepPurple,
        ),
        child: Text(
          "View recurring events",
          style: TextStyle(color: Colors.white),
        ),
      ),
      TextButton(
        onPressed: handleLogout,
        child: Text("Log out"),
      ),
    ];
}

/// Builds the floating action widgets for the calendar page.
Widget buildFloatingActions(
  BuildContext context,
  VoidCallback showEventDialog
) {
  return Padding(
    padding: EdgeInsets.only(top: 0),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 16.0,
      children: [
        FloatingActionButton.extended(
          onPressed: () => context.push('/add_ai_event'),
          heroTag: "ai_add",
          backgroundColor: Colors.deepPurple,
          icon: Icon(Icons.auto_awesome, color: Colors.white),
          label: Text(
            "Add with AI",
            style: TextStyle(color: Colors.white),
          ),
        ),
        FloatingActionButton.extended(
          onPressed: () => _triggerOutlookSync(context),
          heroTag: "outlook_calendar_sync",
          backgroundColor: Colors.deepPurple,
          icon: Icon(Icons.repeat, color: Colors.white),
          label: Text(
            "Sync with Outlook",
            style: TextStyle(color: Colors.white),
          ),
        ),
        FloatingActionButton.extended(
          onPressed: () => _getAndSaveIcsFile(context),
          heroTag: "get_ics_file",
          backgroundColor: Colors.deepPurple,
          icon: Icon(Icons.download, color: Colors.white),
          label: Text(
            "Get .ics file",
            style: TextStyle(color: Colors.white),
          ),
        ),
        FloatingActionButton.extended(
          onPressed: showEventDialog,
          heroTag: "normal_add",
          icon: Icon(Icons.add),
          label: Text("Add an event"),
        ),
      ],
    ),
  );
}

Future<void> _triggerOutlookSync(BuildContext context) async {
  try {
    await OutlookCalendarApiService.triggerSync();
    if (context.mounted) {
      Alerts.showInfoSnackBar(context, "Successfully synced with your Outlook calendar. To view, refresh this calendar, or check out your Outlook calendar!");
    }
  }
  catch (e) {
    if (context.mounted) {
      Alerts.showErrorSnackBar(context, "Failed to trigger the Outlook calendar sync. Please try again later.");
    }
  }
}

Future<void> _getAndSaveIcsFile(BuildContext context) async {
  try {
    final icsString = await OutlookCalendarApiService.getIcsFileContents();
    final path = await getSaveLocation(
      suggestedName: 'calendar.ics', 
      acceptedTypeGroups:  [XTypeGroup(label: 'Calendar (.ics)', extensions: ['ics'], uniformTypeIdentifiers: ['calendar.ics'])]
    );
    if (path != null) {
      final file = File(path.path);
      file.writeAsStringSync(icsString);
      if (context.mounted) {
        Alerts.showInfoSnackBar(context, "The .ics file was successfully saved.");
      }
    }
  }
  catch (e) {
    if (context.mounted) {
        Alerts.showErrorSnackBar(context, "Failed to fetch and save the .ics file. Please try again later.");
      }
  }
  
} 

