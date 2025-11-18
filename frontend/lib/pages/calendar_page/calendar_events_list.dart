import 'package:flutter/material.dart';
import 'package:calendai/models/calendar_event.dart';
import 'package:calendai/models/recurring_calendar_event.dart';
import 'package:calendai/widgets/event_list.dart';

class CalendarEventsList extends StatelessWidget {
  final List<CalendarEvent> events;
  final List<RecurringCalendarEvent> recurringEvents;
  final bool isLoading;

  const CalendarEventsList({
    super.key,
    required this.events,
    required this.recurringEvents,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 18.0),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "Today's events",
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ),
        Expanded(
          child: EventList(
            events: events,
            recurringEvents: recurringEvents,
            isLoading: isLoading
          ),
        ),
      ],
    );
  }
}