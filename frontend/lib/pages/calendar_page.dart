// lib/pages/calendar_page.dart
import 'package:flutter/material.dart';
import 'package:namer_app/models/calendar_event.dart';
import 'package:namer_app/controllers/calendar_controller.dart';
import 'package:namer_app/pages/calendar_page/calendar_app_bar.dart';
import 'package:namer_app/pages/calendar_page/calendar_events.dart';
import 'package:namer_app/pages/calendar_page/calendar_floating_actions.dart';
import 'package:namer_app/pages/calendar_page/calendar_service.dart';
import 'package:namer_app/pages/calendar_page/calendar_view.dart';
import 'package:namer_app/widgets/event_dialog.dart';
import 'package:table_calendar/table_calendar.dart';

class CalendarPage extends StatefulWidget {
  @override
  _CalendarPageState createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  final CalendarController _controller = CalendarController.instance;
  late final CalendarService _eventActionsService;
  CalendarFormat _calendarFormat = CalendarFormat.month;

  @override
  void initState() {
    super.initState();
    _eventActionsService = CalendarService(controller: _controller);
    _controller.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _showEventDialog([CalendarEvent? event]) async {
    await showDialog(
      context: context,
      builder: (context) => EventDialog(
        event: event,
        selectedDay: _controller.selectedDay,
        onSave: _saveEvent,
      ),
    );
  }

  Future<void> _saveEvent(
    CalendarEvent? existingEvent,
    String title,
    String description,
    String? location,
    DateTime startTime,
    DateTime endTime,
  ) async {
    Navigator.pop(context); // Close the dialog
    
    await _eventActionsService.saveEvent(
      context,
      existingEvent: existingEvent,
      title: title,
      description: description,
      location: location,
      startTime: startTime,
      endTime: endTime,
    );
  }

  Future<void> _showEventOptions(CalendarEvent event) async {
    await _eventActionsService.showEventOptions(
      context,
      event,
      onEdit: () => _showEventDialog(event),
    );
  }

  void _onFormatChanged(CalendarFormat format) {
    setState(() {
      _calendarFormat = format;
    });
  }

  @override
  Widget build(BuildContext context) {
    final selectedEvents = _controller.selectedDay != null
        ? _controller.getEventsForDay(_controller.selectedDay!)
        : <CalendarEvent>[];

    return Scaffold(
      appBar: CalendarAppBar(
        controller: _controller,
      ),
      body: Column(
        children: [
          CalendarView(
            controller: _controller,
            calendarFormat: _calendarFormat,
            onFormatChanged: _onFormatChanged,
          ),
          Expanded(
            child: CalendarEvents(
              events: selectedEvents,
              isLoading: _controller.isLoading,
              onEventTap: _showEventOptions,
            ),
          ),
        ],
      ),
      floatingActionButton: CalendarFloatingActions(
        onAddEvent: _showEventDialog,
      ),
    );
  }
}