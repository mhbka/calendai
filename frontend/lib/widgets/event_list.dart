// widgets/event_list.dart
import 'package:flutter/material.dart';
import 'package:namer_app/models/calendar_event.dart';
import 'package:namer_app/models/recurring_calendar_event.dart';
import 'package:namer_app/pages/calendar_page/calendar_dialogs.dart';
import 'package:namer_app/utils/alerts.dart';

class EventList extends StatelessWidget {
  final List<CalendarEvent> events;
  final List<RecurringCalendarEvent> recurringEvents;
  final bool isLoading;

  const EventList({
    super.key,
    required this.events,
    required this.recurringEvents,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (isLoading) LinearProgressIndicator(),
        Expanded(
          child: (events.isEmpty && recurringEvents.isEmpty)
              ? _buildEmpty(context)
              : _buildList(context)
        ),
      ],
    );
  }

  Widget _buildList(BuildContext context) {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
      maxCrossAxisExtent: 1000, 
      crossAxisSpacing: 0.0,
      mainAxisSpacing: 0.0,
      childAspectRatio: 5.4,
    ),
      itemCount: events.length + recurringEvents.length,
      itemBuilder: (context, index) {
        if (index < events.length) {
          final event = events[index];
          return EventListItem(
            event: event
          );
        }
        else {
          final recurringEvent = recurringEvents[index - events.length];
          return EventListItem(
            recurringEvent: recurringEvent
          );
        }
      },
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Text(
        'No events for this day',
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.grey[600],
            ),
      ),
    );
  }
}

class EventListItem extends StatelessWidget {
  final CalendarEvent? event;
  final RecurringCalendarEvent? recurringEvent;

  const EventListItem({
    super.key, 
    this.event, 
    this.recurringEvent,
  });

  @override
  Widget build(BuildContext context) {
    String time;
    String title;
    String description;
    String location;
    Color? color;
    String? groupName;
    bool isException = false;
    
    if (event != null) {
      time = _buildTimeString(event!.startTime, event!.endTime);
      title = event!.title;
      description = event!.description ?? "-";
      location = event!.location ?? "-";
    }
    else if (recurringEvent != null) {
      time = _buildTimeString(recurringEvent!.startTime, recurringEvent!.endTime);
      title = recurringEvent!.title;
      description = recurringEvent!.description ?? "-";
      location = recurringEvent!.location ?? "-";
      color = recurringEvent!.group?.color;
      groupName = recurringEvent!.group?.name;
      isException = recurringEvent!.exceptionId != null;
    }
    else {
      return SizedBox.shrink();
    }

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          children: [
            if (color != null)
              Container(width: 4, color: color),
            Expanded(
              child: ListTile(
                onTap: () {
                  if (event != null) {
                    _openEventDialog(context, event!);
                  }
                  else if (recurringEvent != null) {
                    _openRecurringEventDialog(context, recurringEvent!);
                  }
                  else {
                    Alerts.showErrorDialog(
                      context, 
                      "An internal error occurred", 
                      "No event exists for this list. Apologies for the issue!"
                    );
                  }
                },
                title: _buildTitleComponent(title, recurringEvent != null, isException),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 4),
                    _buildTimeComponent(context, time),
                    SizedBox(height: 4),
                    SizedBox(
                      width: 500,
                      child: Row(
                        children: [
                          Expanded(child: _buildMetadataComponent(description, Icons.description, "Description of the event")),
                          SizedBox(width: 8),
                          Expanded(child: _buildMetadataComponent(location, Icons.location_on, "Location of the event")),
                          SizedBox(width: 8),
                          Spacer(flex: 1), // Aligns the row in groups of 3
                        ],
                      ),
                    ),
                    SizedBox(height: 4),
                    if (recurringEvent != null) 
                      SizedBox(
                        width: 500,
                        child: Row(
                          children: [
                            Expanded(child: _buildMetadataComponent(groupName ?? "Ungrouped", Icons.category, "Group this recurring event belongs to")),
                            SizedBox(width: 8),
                            Spacer(flex: 1), // extra spot for new metadata
                            SizedBox(width: 8),
                            Spacer(flex: 1), // here too
                          ],
                        ),
                      )
                  ],
                ),
                trailing: Icon(Icons.edit, color: Colors.grey[600]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTitleComponent(String title, bool isRecurring, bool isException) {
    return Row(
      mainAxisSize: MainAxisSize.min, 
      crossAxisAlignment: CrossAxisAlignment.start, 
      children: [
        Tooltip(
          message: "The name/title for this event",
          child: Text(title, style: TextStyle(fontWeight: FontWeight.w600))
        ),
        SizedBox(width: 3),
        if (isRecurring) Tooltip(
          message: "This is a ${isException ? "modified " : ""}recurring event",
          child: Icon(Icons.star, size: 13, color: Colors.grey[600]),
        )
      ]
    );
  }

  Widget _buildTimeComponent(BuildContext context, String time) {
    return Row(
      children: [
        Tooltip(
          message: "The start and end time for this event",
          child: Icon(Icons.punch_clock, size: 16, color: Colors.grey[600]),
        ),
        SizedBox(width: 4),
        Expanded(child: Text(time, style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor)),),
      ],
    );
  }

  Widget _buildMetadataComponent(String text, IconData? icon, String? tooltipMessage) {
  String? originalText;
  if (text.length > 18) {
    // around the length where it overflows onto the next line
    originalText = text;
    text = '${text.substring(0, 18)}...';
  }

  return Row(
    children: [
      if (icon != null) 
        Tooltip(
          message: tooltipMessage ?? text, // Use custom message or fallback to text
          child: Icon(icon, size: 16, color: Colors.grey[600]),
        ),
      if (icon != null) SizedBox(width: 4),
      Expanded(
        child: originalText == null ?
          Text(text, style: TextStyle(color: Colors.grey[600])) :
          Tooltip(
            message: originalText,
            child: Text(text, style: TextStyle(color: Colors.grey[600])),
          )
      ),
    ],
  );
}

  String _buildTimeString(DateTime startTime, DateTime endTime) {
    String amOrPm(int hour) => hour < 12 ? 'am' : 'pm';
    int to12HourFormat(int hour) => hour % 12;

    String start = '${to12HourFormat(startTime.hour)}:${startTime.minute.toString().padLeft(2, '0')}${amOrPm(startTime.hour)}';
    String end = '${to12HourFormat(endTime.hour)}:${endTime.minute.toString().padLeft(2, '0')}${amOrPm(endTime.hour)}';
    return '$start - $end';
  }

  Future<void> _openEventDialog(BuildContext context, CalendarEvent event) async {
    await CalendarDialogs.showEventOptions(context, event);
  }

  Future<void> _openRecurringEventDialog(BuildContext context, RecurringCalendarEvent event) async {
    await CalendarDialogs.showRecurringEventOptions(context, event);
  }
}