// lib/widgets/events_section.dart
import 'package:flutter/material.dart';
import 'package:namer_app/constants.dart';
import 'package:namer_app/models/calendar_event.dart';
import 'package:namer_app/widgets/event_list.dart';

class CalendarEvents extends StatelessWidget {
  final List<CalendarEvent> events;
  final bool isLoading;
  final Function(CalendarEvent) onEventTap;

  const CalendarEvents({
    Key? key,
    required this.events,
    required this.isLoading,
    required this.onEventTap,
  }) : super(key: key);

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
            isLoading: isLoading,
            onEventTap: onEventTap,
          ),
        ),
      ],
    );
  }
}