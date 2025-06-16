import 'dart:async';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:namer_app/models/calendar_event.dart';

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
    // TODO: set this up once I figure it out
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
      //windows: initializationSettingsWindows
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
      linux: LinuxNotificationDetails(), 
      //windows: WindowsNotificationDetails()
    );

    await _notifications.show(
      event.id.hashCode,
      'Upcoming Event: ${event.title}',
      'Starting in 10 minutes${event.location != null ? ' at ${event.location}' : ''}',
      notificationDetails,
    );
  }
}