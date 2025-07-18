import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:namer_app/constants.dart';

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
        onPressed: () => context.push('/recurring_events'),
        style: CalendarTheme.primaryButtonStyle,
        child: Text(
          CalendarConstants.viewRecurringEventsLabel,
          style: CalendarConstants.whiteTextStyle,
        ),
      ),
      TextButton(
        onPressed: handleLogout,
        child: Text(CalendarConstants.logoutLabel),
      ),
    ];
}

/// Builds the floating action widgets for the calendar page.
Widget buildFloatingActions(
  BuildContext context,
  VoidCallback showEventDialog
) {
  return Padding(
    padding: CalendarConstants.floatingButtonPadding,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      spacing: CalendarConstants.buttonSpacing,
      children: [
        FloatingActionButton.extended(
          onPressed: () => context.push('/add_ai_event'),
          heroTag: "ai_add",
          backgroundColor: CalendarConstants.primaryColor,
          icon: Icon(Icons.auto_awesome, color: Colors.white),
          label: Text(
            CalendarConstants.addWithAILabel,
            style: CalendarConstants.whiteTextStyle,
          ),
        ),
        FloatingActionButton.extended(
          onPressed: showEventDialog,
          heroTag: "normal_add",
          icon: Icon(Icons.add),
          label: Text(CalendarConstants.addEventLabel),
        ),
      ],
    ),
  );
}

