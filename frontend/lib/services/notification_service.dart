import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:namer_app/models/calendar_event.dart';

/// For interacting with the app's notifications.
class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  static final Map<String, Timer> _activeTimers = {};

  /// Initialize notification settings for the app.
  static Future<void> initialize() async {
    const initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initializationSettingsLinux = LinuxInitializationSettings(defaultActionName: 'test');
    const initializationSettingsIOS = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initializationSettingsWindows = WindowsInitializationSettings(
      appName: 'Calendai', 
      appUserModelId: 'Calendai.Calendai.Desktop.1.0', 
      guid: 'ab0ede05-7eca-4d77-b1b8-533688e2f52d' // NOTE: just a random UUID, should be fine
    );
    
    const initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
      linux: initializationSettingsLinux,
      windows: initializationSettingsWindows
    );
    
    await _notifications.initialize(initializationSettings);
  }

  /// Schedules a reminder for an event, or updates it if it's already been scheduled.
  static void scheduleEventReminder(CalendarEvent event) {
    if (event.id == null) {
      throw ArgumentError("No event ID was found");
    }
    
    final reminderTime = event.startTime.subtract(Duration(minutes: 10));
    final now = DateTime.now();
    
    // Cancel existing timer if any (this handles the update case)
    _activeTimers[event.id]?.cancel();
    _activeTimers.remove(event.id);
    
    if (reminderTime.isAfter(now)) {
      final duration = reminderTime.difference(now);
      
      // Schedule new reminder
      _activeTimers[event.id!] = Timer(duration, () {
        _showNotification(event);
        _activeTimers.remove(event.id);
      });
    }
  }

  static void cancelEventReminder(String eventId) {
    _activeTimers[eventId]?.cancel();
    _activeTimers.remove(eventId);
  }

  // TODO: delete this when no longer needed
  static Future<void> debugNotif(CalendarEvent event) async {
    await _showNotification(event);
  }

  static Future<void> _showNotification(CalendarEvent event) async {
    final androidDetails = AndroidNotificationDetails(
      'calendar_reminders',
      'Calendar Reminders',
      channelDescription: 'Reminders for calendar events',
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