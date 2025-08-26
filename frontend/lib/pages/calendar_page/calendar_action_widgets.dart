import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';


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
          onPressed: showEventDialog,
          heroTag: "normal_add",
          icon: Icon(Icons.add),
          label: Text("Add an event"),
        ),
      ],
    ),
  );
}

