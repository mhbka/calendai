import 'dart:io';
import 'package:dotenv/dotenv.dart';
import 'package:namer_app/main.dart';
import 'package:namer_app/models/calendar_event.dart';
import 'package:namer_app/services/notification_service.dart';
import 'package:tray_manager/tray_manager.dart';

/// Validates and returns the env vars for the app.
DotEnv initEnvVars() {
  var env = DotEnv(includePlatformEnvironment: true)..load();
  if (!env.isEveryDefined(['supabase_url', 'supabase_anon_key', 'api_base_url', 'google_client_id', 'google_client_secret'])) {
    throw 'Not all required env vars were detected';
  }
  return env;
}

/// Initializes the Windows system tray for the app.
Future<void> initSystemTray() async {
  await trayManager.setIcon(
    Platform.isWindows
      ? 'images/tray_icon.ico'
      : 'images/tray_icon.png',
  );
  Menu menu = Menu(
    items: [
      MenuItem(
        key: 'show_window',
        label: 'Show Window',
      ),
      MenuItem.separator(),
      MenuItem( 
        key: 'test',
        label: 'test',
        onClick: (item) {
          var event = CalendarEvent(
            id: uuid.v4(), 
            title: 'test', 
            description: 'test 2', 
            startTime: DateTime.now(), 
            endTime: DateTime.now()
          );
          NotificationService.debugNotif(event);
          }
      ),
    ],
  );
  await trayManager.setContextMenu(menu);
}