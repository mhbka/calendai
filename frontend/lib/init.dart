import 'dart:io';
import 'dart:ui';
import 'package:dotenv/dotenv.dart';
import 'package:flutter/material.dart';
import 'package:namer_app/main.dart';
import 'package:namer_app/services/notification_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

/// Initializes any plugins/dependencies.
Future<void> initDeps() async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  await NotificationService.initialize();
  await windowManager.ensureInitialized();

  await Supabase.initialize(
    url: envVars['supabase_url']!,
    anonKey: envVars['supabase_anon_key']!
  );
  await Supabase.instance.client.auth.refreshSession();
}

/// Validates and returns the env vars for the app.
DotEnv initEnvVars() {
  var env = DotEnv(includePlatformEnvironment: true)..load();
  if (!env.isEveryDefined([
    'supabase_url', 
    'supabase_anon_key', 
    'api_base_url', 
    'google_client_id', 
    'google_client_secret'
    ])
  ) {
    throw 'Not all required env vars were detected';
  }
  return env;
}

/// Initialize the window's settings.
Future<void> initWindowSettings() async {
  //windowManager.setPreventClose(true);
  await windowManager.setSize(Size(1366, 768));
}

/// Initializes the Windows system tray for the app.
/// 
/// Note that the handler functions for each option are in the `system_tray` mixin.
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
        label: 'Open',
      ),
      MenuItem.separator(),
      MenuItem( 
        key: 'say_hello',
        label: 'Say Hello!'
      ),
      MenuItem.separator(),
      MenuItem(
        key: 'show_ai_event',
        label: 'Add event with AI'
      )
    ],
  );
  await trayManager.setContextMenu(menu);
}