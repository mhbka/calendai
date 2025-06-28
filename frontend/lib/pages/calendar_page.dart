import 'package:flutter/material.dart';
import 'package:namer_app/models/calendar_event.dart';
import 'package:namer_app/services/calendar_api_service.dart';
import 'package:namer_app/services/notification_service.dart';
import 'package:table_calendar/table_calendar.dart';
import 'dart:async';

class CalendarPage extends StatefulWidget {
  @override
  _CalendarPageState createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  late final ValueNotifier<List<CalendarEvent>> _selectedEvents;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  List<CalendarEvent> _events = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _selectedEvents = ValueNotifier(_getEventsForDay(_selectedDay!));
    _loadEvents();
  }

  @override
  void dispose() {
    _selectedEvents.dispose();
    super.dispose();
  }

  List<CalendarEvent> _getEventsForDay(DateTime day) {
    return _events.where((event) {
      return isSameDay(event.startTime, day);
    }).toList();
  }

  Future<void> _loadEvents() async {
    setState(() => _isLoading = true);
    try {
      final startOfMonth = DateTime(_focusedDay.year, _focusedDay.month, 1);
      final endOfMonth = DateTime(_focusedDay.year, _focusedDay.month + 1, 0);
      
      final events = await CalendarApiService.fetchEvents(startOfMonth, endOfMonth);
      setState(() {
        _events = events;
        _selectedEvents.value = _getEventsForDay(_selectedDay!);
      });
      
      // Schedule reminders for all events
      for (final event in events) {
        NotificationService.scheduleEventReminder(event);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load events: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
        _selectedEvents.value = _getEventsForDay(selectedDay);
      });
    }
  }

  Future<void> _showEventDialog([CalendarEvent? event]) async {
    final isEditing = event != null;
    final titleController = TextEditingController(text: event?.title ?? '');
    final descriptionController = TextEditingController(text: event?.description ?? '');
    final locationController = TextEditingController(text: event?.location ?? '');
    
    DateTime startTime = event?.startTime ?? _selectedDay!.add(Duration(hours: 9));
    DateTime endTime = event?.endTime ?? _selectedDay!.add(Duration(hours: 10));
    
    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEditing ? 'Edit Event' : 'Add Event'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(labelText: 'Title'),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: InputDecoration(labelText: 'Description'),
                  maxLines: 3,
                ),
                SizedBox(height: 16),
                TextField(
                  controller: locationController,
                  decoration: InputDecoration(labelText: 'Location (optional)'),
                ),
                SizedBox(height: 16),
                ListTile(
                  title: Text('Start Time'),
                  subtitle: Text('${startTime.day}/${startTime.month}/${startTime.year} ${startTime.hour}:${startTime.minute.toString().padLeft(2, '0')}'),
                  trailing: Icon(Icons.edit),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: startTime,
                      firstDate: DateTime.now().subtract(Duration(days: 365)),
                      lastDate: DateTime.now().add(Duration(days: 365)),
                    );
                    if (date != null) {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(startTime),
                      );
                      if (time != null) {
                        setDialogState(() {
                          startTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
                          if (endTime.isBefore(startTime)) {
                            endTime = startTime.add(Duration(hours: 1));
                          }
                        });
                      }
                    }
                  },
                ),
                ListTile(
                  title: Text('End Time'),
                  subtitle: Text('${endTime.day}/${endTime.month}/${endTime.year} ${endTime.hour}:${endTime.minute.toString().padLeft(2, '0')}'),
                  trailing: Icon(Icons.edit),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: endTime,
                      firstDate: startTime,
                      lastDate: DateTime.now().add(Duration(days: 365)),
                    );
                    if (date != null) {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(endTime),
                      );
                      if (time != null) {
                        setDialogState(() {
                          endTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
                        });
                      }
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            if (isEditing)
              TextButton(
                onPressed: () => _deleteEvent(event),
                child: Text('Delete', style: TextStyle(color: Colors.red)),
              ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => _saveEvent(
                event,
                titleController.text,
                descriptionController.text,
                locationController.text.isEmpty ? null : locationController.text,
                startTime,
                endTime,
              ),
              child: Text(isEditing ? 'Update' : 'Add'),
            ),
          ],
        ),
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
    if (title.isEmpty) return;

    Navigator.pop(context);
    setState(() => _isLoading = true);

    try {
      CalendarEvent newEvent;
      
      if (existingEvent != null) {
        // Update existing event
        newEvent = existingEvent.copyWith(
          title: title,
          description: description,
          location: location,
          startTime: startTime,
          endTime: endTime,
        );
        await CalendarApiService.updateEvent(newEvent);
        
        // Update local list
        final index = _events.indexWhere((e) => e.id == existingEvent.id);
        if (index != -1) {
          _events[index] = newEvent;
        }
      } else {
        // Create new event
        newEvent = CalendarEvent(
          id: '',
          title: title,
          description: description,
          location: location,
          startTime: startTime,
          endTime: endTime,
        );
        final createdEvent = await CalendarApiService.createEvent(newEvent);
        _events.add(createdEvent);
        newEvent = createdEvent;
      }

      // Schedule reminder
      NotificationService.scheduleEventReminder(newEvent);
      
      setState(() {
        _selectedEvents.value = _getEventsForDay(_selectedDay!);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(existingEvent != null ? 'Event updated' : 'Event added')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save event: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteEvent(CalendarEvent event) async {
    Navigator.pop(context);
    
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
      setState(() => _isLoading = true);
      
      try {
        await CalendarApiService.deleteEvent(event.id);
        NotificationService.cancelEventReminder(event.id);
        
        setState(() {
          _events.removeWhere((e) => e.id == event.id);
          _selectedEvents.value = _getEventsForDay(_selectedDay!);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Event deleted')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete event: $e')),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Calendar'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadEvents,
          ),
        ],
      ),
      body: Column(
        children: [
          TableCalendar<CalendarEvent>(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            eventLoader: _getEventsForDay,
            startingDayOfWeek: StartingDayOfWeek.monday,
            calendarStyle: CalendarStyle(
              outsideDaysVisible: false,
            ),
            onDaySelected: _onDaySelected,
            onFormatChanged: (format) {
              if (_calendarFormat != format) {
                setState(() {
                  _calendarFormat = format;
                });
              }
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
              _loadEvents();
            },
            selectedDayPredicate: (day) {
              return isSameDay(_selectedDay, day);
            },
          ),
          const SizedBox(height: 8.0),
          if (_isLoading)
            LinearProgressIndicator(),
          Expanded(
            child: ValueListenableBuilder<List<CalendarEvent>>(
              valueListenable: _selectedEvents,
              builder: (context, value, _) {
                return ListView.builder(
                  itemCount: value.length,
                  itemBuilder: (context, index) {
                    final event = value[index];
                    return Card(
                      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      child: ListTile(
                        onTap: () => _showEventDialog(event),
                        title: Text(event.title),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(event.description),
                            Text(
                              '${event.startTime.hour}:${event.startTime.minute.toString().padLeft(2, '0')} - ${event.endTime.hour}:${event.endTime.minute.toString().padLeft(2, '0')}',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            if (event.location != null)
                              Text('📍 ${event.location}'),
                          ],
                        ),
                        trailing: Icon(Icons.edit),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showEventDialog(),
        child: Icon(Icons.add),
      ),
    );
  }
}

// Dependencies to add to pubspec.yaml:
/*
dependencies:
  flutter:
    sdk: flutter
  table_calendar: ^3.0.9
  flutter_local_notifications: ^16.3.2
  http: ^1.1.0
*/