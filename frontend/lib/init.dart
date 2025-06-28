import 'dart:io';
import 'dart:ui';
import 'package:dotenv/dotenv.dart';
import 'package:flutter/material.dart';
import 'package:namer_app/services/notification_service.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

/// Initializes any plugins/dependencies.
Future<void> initDeps() async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  await NotificationService.initialize();
  await windowManager.ensureInitialized();
}

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
        key: 'say_hello',
        label: 'Say Hello!'
      ),
    ],
  );
  await trayManager.setContextMenu(menu);
}