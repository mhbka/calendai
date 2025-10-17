import 'dart:io';
import 'dart:ui';
import 'package:dotenv/dotenv.dart';
import 'package:flutter/material.dart';
import 'package:namer_app/main.dart';
import 'package:namer_app/services/notification_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:win32_registry/win32_registry.dart';
import 'package:window_manager/window_manager.dart';

/// Initializes any plugins/dependencies.
Future<void> initDeps() async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  await NotificationService.initialize();
  await windowManager.ensureInitialized();

  if (envVars.envType == 'DEV') {
    await registerCustomUri();
  }

  await Supabase.initialize(
    url: envVars.supabaseUrl,
    anonKey: envVars.supabaseAnonKey
  );
  try {
    await Supabase.instance.client.auth.refreshSession();
  } catch (e) {
    print("Auth not refreshed (likely not logged in)");
  }
}

/// Validates and returns the env vars for the app.
EnvVars initEnvVars() {
  var env = DotEnv(includePlatformEnvironment: true)..load();
  return EnvVars(
    env['ENV_TYPE']!,
    env['SUPABASE_URL']!,
    env['SUPABASE_ANON_KEY']!,
    env['API_BASE_URL']!
  );
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

/// Registers the custom URI scheme for Windows manually, for OAuth callbacks.
/// 
/// This should only be done for development purposes; in a normal app install, `msix` will handle this.
Future<void> registerCustomUri() async {
  String appPath = Platform.resolvedExecutable;

  String protocolRegKey = 'Software\\Classes\\calendai';
  RegistryValue protocolRegValue = const RegistryValue.string(
    'URL Protocol',
    '',
  );
  String protocolCmdRegKey = 'shell\\open\\command';
  RegistryValue protocolCmdRegValue = RegistryValue.string(
    '',
    '"$appPath" "%1"',
  );

  final regKey = Registry.currentUser.createKey(protocolRegKey);
  regKey.createValue(protocolRegValue);
  regKey.createKey(protocolCmdRegKey).createValue(protocolCmdRegValue);
} 