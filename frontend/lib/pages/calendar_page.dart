import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

// Event model
class CalendarEvent {
  final String id;
  final String title;
  final String description;
  final DateTime startTime;
  final DateTime endTime;
  final String? location;

  CalendarEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.startTime,
    required this.endTime,
    this.location,
  });

  factory CalendarEvent.fromJson(Map<String, dynamic> json) {
    return CalendarEvent(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      startTime: DateTime.parse(json['startTime']),
      endTime: DateTime.parse(json['endTime']),
      location: json['location'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'location': location,
    };
  }

  CalendarEvent copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? startTime,
    DateTime? endTime,
    String? location,
  }) {
    return CalendarEvent(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      location: location ?? this.location,
    );
  }
}

// API Service
class CalendarApiService {
  static const String baseUrl = 'https://your-backend-api.com/api';
  
  // Fetch events for a date range
  static Future<List<CalendarEvent>> fetchEvents(DateTime start, DateTime end) async {
    try {
      // Stub implementation - replace with actual API call
      final response = await http.get(
        Uri.parse('$baseUrl/events?start=${start.toIso8601String()}&end=${end.toIso8601String()}'),
        headers: {'Content-Type': 'application/json'},
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => CalendarEvent.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load events');
      }
    } catch (e) {
      // Return mock data for now
      return _getMockEvents();
    }
  }

  static Future<CalendarEvent> createEvent(CalendarEvent event) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/events'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(event.toJson()),
      );
      
      if (response.statusCode == 201) {
        return CalendarEvent.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to create event');
      }
    } catch (e) {
      // Return the event with a generated ID for now
      return event.copyWith(id: DateTime.now().millisecondsSinceEpoch.toString());
    }
  }

  static Future<CalendarEvent> updateEvent(CalendarEvent event) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/events/${event.id}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(event.toJson()),
      );
      
      if (response.statusCode == 200) {
        return CalendarEvent.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to update event');
      }
    } catch (e) {
      return event;
    }
  }

  static Future<void> deleteEvent(String eventId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/events/$eventId'),
        headers: {'Content-Type': 'application/json'},
      );
      
      if (response.statusCode != 200) {
        throw Exception('Failed to delete event');
      }
    } catch (e) {
      // Silently handle for stub
    }
  }

  // Mock data for testing
  static List<CalendarEvent> _getMockEvents() {
    final now = DateTime.now();
    return [
      CalendarEvent(
        id: '1',
        title: 'Team Meeting',
        description: 'Weekly team sync',
        startTime: now.add(Duration(hours: 2)),
        endTime: now.add(Duration(hours: 3)),
        location: 'Conference Room A',
      ),
      CalendarEvent(
        id: '2',
        title: 'Doctor Appointment',
        description: 'Annual checkup',
        startTime: now.add(Duration(days: 1, hours: 10)),
        endTime: now.add(Duration(days: 1, hours: 11)),
        location: 'Medical Center',
      ),
    ];
  }
}

// Notification Service
class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  static final Map<String, Timer> _activeTimers = {};

  static Future<void> initialize() async {
    const initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initializationSettingsLinux = LinuxInitializationSettings(defaultActionName: 'test');
    const initializationSettingsIOS = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    /*
    const initializationSettingsWindows = WindowsInitializationSettings(
      appName: 'Calendai', 
      appUserModelId: appUserModelId, 
      guid: guid
    );
    */
    
    const initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
      linux: initializationSettingsLinux,
      // windows: initializationSettingsWindows
    );
    
    await _notifications.initialize(initializationSettings);
  }

  static void scheduleEventReminder(CalendarEvent event) {
    final reminderTime = event.startTime.subtract(Duration(minutes: 10));
    final now = DateTime.now();
    
    if (reminderTime.isAfter(now)) {
      final duration = reminderTime.difference(now);
      
      // Cancel existing timer if any
      _activeTimers[event.id]?.cancel();
      
      // Schedule new reminder
      _activeTimers[event.id] = Timer(duration, () {
        _showNotification(event);
        _activeTimers.remove(event.id);
      });
    }
  }

  static void cancelEventReminder(String eventId) {
    _activeTimers[eventId]?.cancel();
    _activeTimers.remove(eventId);
  }

  static Future<void> _showNotification(CalendarEvent event) async {
    const notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        'calendar_reminders',
        'Calendar Reminders',
        channelDescription: 'Reminders for calendar events',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );

    await _notifications.show(
      event.id.hashCode,
      'Upcoming Event: ${event.title}',
      'Starting in 10 minutes${event.location != null ? ' at ${event.location}' : ''}',
      notificationDetails,
    );
  }
}

// Main Calendar Page
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
    NotificationService.initialize();
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