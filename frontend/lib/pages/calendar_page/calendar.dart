import 'package:flutter/material.dart';

import 'package:calendai/models/calendar_event.dart';
import 'package:calendai/controllers/calendar_controller.dart';
import 'package:table_calendar/table_calendar.dart';

/// The calendar.
class Calendar extends StatefulWidget {
  final CalendarController controller;
  final Function(CalendarFormat) onFormatChanged;
  final CalendarFormat calendarFormat;

  const Calendar({
    Key? key,
    required this.controller,
    required this.onFormatChanged,
    required this.calendarFormat,
  }) : super(key: key);

  @override
  State<Calendar> createState() => _CalendarState();
}

class _CalendarState extends State<Calendar> {
  @override
  Widget build(BuildContext context) {
    return TableCalendar<CalendarEvent>(
      firstDay: DateTime.utc(2020, 1, 1),
      lastDay: DateTime.utc(2030, 12, 31),
      focusedDay: widget.controller.focusedDay,
      calendarFormat: widget.calendarFormat,
      eventLoader: widget.controller.getAllEventsForDay,
      startingDayOfWeek: StartingDayOfWeek.monday,
      calendarStyle: CalendarStyle(outsideDaysVisible: false),
      onDaySelected: widget.controller.setSelectedDay,
      onFormatChanged: (format) {
        if (widget.calendarFormat != format) {
          widget.onFormatChanged(format);
        }
      },
      onPageChanged: widget.controller.setFocusedDay,
      selectedDayPredicate: (day) {
        return isSameDay(widget.controller.selectedDay, day);
      },
    );
  }
}