// lib/pages/calendar_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:namer_app/models/calendar_event.dart';
import 'package:namer_app/controllers/calendar_controller.dart';
import 'package:namer_app/models/recurring_calendar_event.dart';
import 'package:namer_app/pages/base_page.dart';
import 'package:namer_app/pages/calendar_page/calendar_action_widgets.dart';
import 'package:namer_app/pages/calendar_page/calendar_events_list.dart';
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
  CalendarFormat _calendarFormat = CalendarFormat.month;

  @override
  void initState() {
    super.initState();
    _controller.loadEvents().catchError((err) {
      if (mounted) Alerts.showErrorSnackBar(context, "Failed to load events: $err. Please try again later");
    });
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
        onSubmit: (editedEvent) {
          _controller.saveEvent(editedEvent, event == null)
            .then((v) => {if (context.mounted) Navigator.pop(context)})
            .catchError((err) async {
              if (context.mounted) {
                await Alerts.showErrorDialog(
                  context, 
                  "Error", 
                  "Failed to save the event: $err. Please try again later."
                );
              }
              return <dynamic>{};
            });
          },
      ),
    );
  }

  void _onFormatChanged(CalendarFormat format) {
    setState(() {
      _calendarFormat = format;
    });
  }

  Future<void> _handleRefresh() async {
    try {
      await _controller.loadEvents().catchError((err) {
      if (mounted) Alerts.showErrorSnackBar(context, "Failed to load events: $err. Please try again later");
    });;
    } catch (e) {
      if (mounted) {
        Alerts.showErrorDialog(
          context, 
          "Error",
          "Unable to load calendar events: $e. Please try again later."
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
    final selectedRecurringEvents = _controller.selectedDay != null
        ? _controller.getRecurringEventsForDay(_controller.selectedDay!)
        : <RecurringCalendarEvent>[];

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
              recurringEvents: selectedRecurringEvents,
              isLoading: _controller.isLoading,
            ),
          ),
        ],
      ),
      appBarActions: buildCalendarAppbarActions(context, _handleRefresh, _handleLogout),
      floatingActions: buildFloatingActions(context, _showEventDialog)
    );
  }
}