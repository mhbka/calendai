import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:calendai/models/calendar_event.dart';
import 'package:calendai/services/calendar_api_service.dart';
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static Set<String> _scheduledEventIds = {};
  static Timer? _syncTimer;

  /// Deterministic notification ID from the event ID.
  static int _notificationId(String eventId) {
    return eventId.codeUnits.fold(0, (a, b) => (a * 31 + b) & 0x7fffffff);
  }

  /// Shared notification details for all scheduled event notifications.
  static const AndroidNotificationDetails _androidDetails =
      AndroidNotificationDetails(
    'calendar_notifications',
    'Calendar Notifications',
    channelDescription: 'Notifications for calendar events',
    importance: Importance.high,
    priority: Priority.high,
  );

  static WindowsNotificationDetails _windowsDetails =
      WindowsNotificationDetails(
    audio: WindowsNotificationAudio.preset(
      sound: WindowsNotificationSound.alarm6,
    ),
  );

  static NotificationDetails _scheduledNotificationDetails =
      NotificationDetails(
    android: _androidDetails,
    windows: _windowsDetails,
  );

  static Future<void> initialize() async {
    // Ensure channel creation on Android
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const WindowsInitializationSettings initializationSettingsWindows =
        WindowsInitializationSettings(
      appName: 'Calendai',
      appUserModelId: 'Calendai.Calendai.Desktop.1.0',
      guid: 'ab0ede05-7eca-4d77-b1b8-533688e2f52d',
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      windows: initializationSettingsWindows,
    );

    tz.initializeDatabase([]);

    await _notifications.initialize(initializationSettings);

    // Android requires explicit channel creation on some versions
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'calendar_notifications',
      'Calendar Notifications',
      description: 'Notifications for calendar events',
      importance: Importance.high,
    );
    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    startPeriodicSync();
  }

  /// Schedule or update the event's 10-minute-prior notification.
  static Future<void> scheduleEventNotification(CalendarEvent event) async {
    if (event.id == null) {
      throw ArgumentError("Event has no ID");
    }

    final int notifId = _notificationId(event.id!);
    final DateTime notificationTime =
        event.startTime.subtract(const Duration(minutes: 10));
    final DateTime now = DateTime.now();

    // Always remove any existing scheduled notification for this event
    await _notifications.cancel(notifId);

    if (notificationTime.isAfter(now)) {
      await _notifications.zonedSchedule(
        notifId,
        'Upcoming Event: ${event.title}',
        'Starting in 10 minutes${event.location != null ? ' at ${event.location}' : ''}',
        tz.TZDateTime.from(notificationTime, tz.local),
        _scheduledNotificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );

      _scheduledEventIds.add(event.id!);
    }
  }

  static void cancelEventNotification(String eventId) {
    final int notifId = _notificationId(eventId);
    _notifications.cancel(notifId);
    _scheduledEventIds.remove(eventId);
  }

  static void startPeriodicSync() {
    _syncNotificationsWithEvents();
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(
      const Duration(minutes: 2),
      (_) => _syncNotificationsWithEvents(),
    );
  }

  static void stopPeriodicSync() {
    _syncTimer?.cancel();
    _syncTimer = null;
  }

  /// Align the scheduled notifications with today’s events.
  static Future<void> _syncNotificationsWithEvents() async {
    try {
      final events = await _fetchTodaysEvents();
      final Set<String> eventIdsToday =
          events.map((e) => e.id!).toSet();

      // Remove notifications for events that no longer exist
      final removed = _scheduledEventIds.difference(eventIdsToday);
      for (final id in removed) {
        cancelEventNotification(id);
      }

      // Ensure each event for today has an up-to-date notification
      for (final event in events) {
        await scheduleEventNotification(event);
      }

      // DO NOT overwrite _scheduledEventIds here.
      // It is updated by schedule/cancel only.
    } catch (e) {
      print('Error syncing notifications: $e');
    }
  }

  static Future<List<CalendarEvent>> _fetchTodaysEvents() async {
    final now = DateTime.now();
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59);
    return CalendarApiService.fetchEvents(now, endOfDay);
  }

  /// Debug method — shows a notification immediately.
  static Future<void> debugNotif(CalendarEvent event) async {
    await _notifications.show(
      _notificationId(event.id!),
      'Upcoming Event: ${event.title}',
      'Starting in 10 minutes${event.location != null ? ' at ${event.location}' : ''}',
      NotificationDetails(
        android: _androidDetails,
        windows: _windowsDetails,
      ),
    );
  }
}
