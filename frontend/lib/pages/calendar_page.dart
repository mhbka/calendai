import 'package:flutter/material.dart';
import 'package:namer_app/models/calendar_event.dart';
import 'package:namer_app/controllers/calendar_controller.dart';
import 'package:namer_app/pages/ai_event_page.dart';
import 'package:namer_app/widgets/event_dialog.dart';
import 'package:namer_app/widgets/event_list.dart';
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

  Future<void> _navToAiEventPage() async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEventPage(),
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
    
    try {
      await _controller.saveEvent(
        existingEvent: existingEvent,
        title: title,
        description: description,
        location: location,
        startTime: startTime,
        endTime: endTime,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(existingEvent != null ? 'Event updated' : 'Event added'),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save event: $e')),
      );
    }
  }

  Future<void> _showDeleteConfirmation(CalendarEvent event) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Event'),
        content: Text('Are you sure you want to delete "${event.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _controller.deleteEvent(event);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Event deleted')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete event: $e')),
        );
      }
    }
  }

  Future<void> _showEventOptions(CalendarEvent event) async {
    await showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(Icons.edit),
            title: Text('Edit Event'),
            onTap: () {
              Navigator.pop(context);
              _showEventDialog(event);
            },
          ),
          ListTile(
            leading: Icon(Icons.delete, color: Colors.red),
            title: Text('Delete Event', style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pop(context);
              _showDeleteConfirmation(event);
            },
          ),
          ListTile(
            leading: Icon(Icons.cancel),
            title: Text('Cancel'),
            onTap: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedEvents = _controller.selectedDay != null
        ? _controller.getEventsForDay(_controller.selectedDay!)
        : <CalendarEvent>[];

    return Scaffold(
      appBar: AppBar(
        title: Text('Calendai'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () async {
              try {
                await _controller.loadEvents();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to load events: $e')),
                );
              }
            },
          ),
          TextButton(
            onPressed: () {}, 
            child: Text('Log out')
          ),
        ],
      ),
      body: Column(
        children: [
          TableCalendar<CalendarEvent>(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _controller.focusedDay,
            calendarFormat: _calendarFormat,
            eventLoader: _controller.getEventsForDay,
            startingDayOfWeek: StartingDayOfWeek.monday,
            calendarStyle: CalendarStyle(
              outsideDaysVisible: false,
            ),
            onDaySelected: _controller.setSelectedDay,
            onFormatChanged: (format) {
              if (_calendarFormat != format) {
                setState(() {
                  _calendarFormat = format;
                });
              }
            },
            onPageChanged: _controller.setFocusedDay,
            selectedDayPredicate: (day) {
              return isSameDay(_controller.selectedDay, day);
            },
          ),
          const SizedBox(height: 8.0),
          Expanded(
            child: EventList(
              events: selectedEvents,
              isLoading: _controller.isLoading,
              onEventTap: _showEventOptions,
            ),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: EdgeInsets.only(top: 0), 
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 16,
          children: [
            FloatingActionButton.extended(
              onPressed: _navToAiEventPage,
              heroTag: "ai_add", 
              backgroundColor: Colors.deepPurple,
              icon: Icon(Icons.auto_awesome, color: Colors.white),
              label: Text('Add with AI', style: TextStyle(color: Colors.white)),
            ),
            FloatingActionButton.extended(
              onPressed: _showEventDialog,
              heroTag: "normal_add", 
              icon: Icon(Icons.add),
              label: Text('Add Event')
            ),
          ],
        )
      ),
    );
  }
}