// lib/pages/calendar_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:namer_app/constants.dart';
import 'package:namer_app/models/calendar_event.dart';
import 'package:namer_app/controllers/calendar_controller.dart';
import 'package:namer_app/pages/base_page.dart';
import 'package:namer_app/pages/calendar_page/calendar_action_widgets.dart';
import 'package:namer_app/pages/calendar_page/calendar_events.dart';
import 'package:namer_app/pages/calendar_page/calendar_dialogs.dart';
import 'package:namer_app/pages/calendar_page/calendar.dart';
import 'package:namer_app/utils/alerts.dart';
import 'package:namer_app/widgets/event_dialog.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:table_calendar/table_calendar.dart';

class CalendarPage extends StatefulWidget {
  @override
  _CalendarPageState createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  final CalendarController _controller = CalendarController.instance;
  late final CalendarDialogs _calendarDialogs;
  CalendarFormat _calendarFormat = CalendarFormat.month;

  @override
  void initState() {
    super.initState();
    _controller
      .loadEvents()
      .catchError((err) {
        if (mounted) Alerts.showErrorSnackBar(context, "Failed to load events: $err. Please try again later");
      });
    _calendarDialogs = CalendarDialogs(controller: _controller);
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
      await _calendarDialogs.saveEvent(
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
    await _calendarDialogs.showEventOptions(
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

  Future<void> _handleRefresh() async {
    try {
      await _controller.loadEvents();
    } catch (e) {
      if (mounted) {
        _calendarDialogs.showSnackBar(
          context, 
          Text('${CalendarConstants.failedToLoadMessage}: $e')
        );
      }
    }
  }
  
  Future<void> _handleLogout() async {
    await Supabase.instance.client.auth.signOut();
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final selectedEvents = _controller.selectedDay != null
        ? _controller.getEventsForDay(_controller.selectedDay!)
        : <CalendarEvent>[];

    return BasePage(
      title: 'Calendai', 
      body: Column(
        children: [
          Calendar(
            controller: _controller,
            calendarFormat: _calendarFormat,
            onFormatChanged: _onFormatChanged,
          ),
          Expanded(
            child: CalendarEventsList(
              events: selectedEvents,
              isLoading: _controller.isLoading,
              onEventTap: _showEventOptions,
            ),
          ),
        ],
      ),
      appBarActions: buildCalendarAppbarActions(context, _handleRefresh, _handleLogout),
      floatingActions: buildFloatingActions(context, _showEventDialog)
    );
  }
}