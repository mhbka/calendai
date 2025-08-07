// lib/widgets/events_section.dart
import 'package:flutter/material.dart';
import 'package:namer_app/constants.dart';
import 'package:namer_app/models/calendar_event.dart';
import 'package:namer_app/models/recurring_calendar_event.dart';
import 'package:namer_app/widgets/event_list.dart';

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
        const SizedBox(height: CalendarConstants.defaultSpacing),
        Padding(
          padding: CalendarConstants.defaultPadding,
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              CalendarConstants.todaysEventsTitle,
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