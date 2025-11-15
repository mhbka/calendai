import 'dart:async';
import 'dart:collection';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:namer_app/models/calendar_event.dart';
import 'package:namer_app/services/calendar_api_service.dart';
import 'package:timezone/timezone.dart' as tz;

/// For interacting with the app's notifications.
class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  static Set<String> _scheduledEventIds = {};
  static Timer? _syncTimer;

  /// Initialize notification settings for the app.
  static Future<void> initialize() async {
    const initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initializationSettingsWindows = WindowsInitializationSettings(
      appName: 'Calendai', 
      appUserModelId: 'Calendai.Calendai.Desktop.1.0', 
      guid: 'ab0ede05-7eca-4d77-b1b8-533688e2f52d' // NOTE: just a random UUID, should be fine
    );
    const initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      windows: initializationSettingsWindows
    );
    await _notifications.initialize(initializationSettings);
    startPeriodicSync();
  }

  /// Schedules a Notification for an event, or updates it if it's already been scheduled.
  static Future<void> scheduleEventNotification(CalendarEvent event) async {
  if (event.id == null) {
    throw ArgumentError("No event ID was found");
  }
  
  final notificationTime = event.startTime.subtract(Duration(minutes: 10));
  final now = DateTime.now();
  
  // Cancel existing notification if any
  await _notifications.cancel(event.id.hashCode);
  
  if (notificationTime.isAfter(now)) {
    await _notifications.zonedSchedule(
      event.id.hashCode,
      'Upcoming Event: ${event.title}',
      'Starting in 10 minutes${event.location != null ? ' at ${event.location}' : ''}',
      tz.TZDateTime.from(notificationTime, tz.local),
      NotificationDetails(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );

    // already checked for null above
    _scheduledEventIds.add(event.id!);
  }
}

  /// Cancels an event's notification.
  static void cancelEventNotification(String eventId) {
    _notifications.cancel(eventId.hashCode);
    _scheduledEventIds.remove(eventId);
  }

  /// Starts a periodic task that syncs notifications with today's events.
  /// Runs immediately and then every 2 minutes.
  static void startPeriodicSync() {
    // Run immediately
    _syncNotificationsWithEvents();
    
    // Then run every 5 minutes
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(Duration(minutes: 2), (_) {
      _syncNotificationsWithEvents();
    });
  }

  /// Stops the periodic sync task.
  static void stopPeriodicSync() {
    _syncTimer?.cancel();
    _syncTimer = null;
  }

  /// Syncs scheduled notifications with current events.
  static Future<void> _syncNotificationsWithEvents() async {
    try {
      final currentEvents = await _fetchTodaysEvents();
      final currentEventIds = currentEvents.map((e) => e.id!).toSet();
    
      final eventsToRemove = _scheduledEventIds.difference(currentEventIds);
      for (final eventId in eventsToRemove) {
        cancelEventNotification(eventId);
      }
      for (final event in currentEvents) {
        scheduleEventNotification(event);
      }
  
      _scheduledEventIds = currentEventIds;
      
    } catch (e) {
      // TODO: Add proper error logging/handling
      print('Error syncing notifications: $e');
    }
  }

  /// Fetch the events for today.
  static Future<List<CalendarEvent>> _fetchTodaysEvents() async {
    var currentDt = DateTime.now();
    var eodDt = DateTime(
      currentDt.year,
      currentDt.month,
      currentDt.day,
      23,
      59
    );
    return await CalendarApiService.fetchEvents(currentDt, eodDt);
  }

  // TODO: delete this when no longer needed
  static Future<void> debugNotif(CalendarEvent event) async {
    await _showNotification(event);
  }

  static Future<void> _showNotification(CalendarEvent event) async {
    final androidDetails = AndroidNotificationDetails(
      'calendar_Notifications',
      'Calendar Notifications',
      channelDescription: 'Notifications for calendar events',
      importance: Importance.high,
      priority: Priority.high,
    );
    final windowsDetails = WindowsNotificationDetails(
      audio: WindowsNotificationAudio.preset(sound: WindowsNotificationSound.alarm6) // TODO: what's the most alarming sound I can play
    );
    final notificationDetails = NotificationDetails(
      android: androidDetails,
      linux: const LinuxNotificationDetails(), // TODO: if I'm really supporting linux, fill these details out
      windows: windowsDetails
    );
    await _notifications.show(
      event.id.hashCode,
      'Upcoming Event: ${event.title}',
      'Starting in 10 minutes${event.location != null ? ' at ${event.location}' : ''}',
      notificationDetails,
    );
  }
}