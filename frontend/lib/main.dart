import 'dart:io';
import 'dart:ui';
import 'package:dotenv/dotenv.dart';
import 'package:flutter/material.dart';
import 'package:namer_app/models/calendar_event.dart';
import 'package:namer_app/services/notification_service.dart';
import 'package:namer_app/mixins/system_tray.dart';
import 'package:namer_app/router.dart'; 
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:uuid/uuid.dart';

/// The env vars for the program.
late final DotEnv envVars;

/// The UUID generator for the app.
final Uuid uuid = Uuid();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  NotificationService.initialize();

  envVars = initEnvVars();  

  await initSystemTray();
  
  await Supabase.initialize(
    url: envVars['supabase_url']!,
    anonKey: envVars['supabase_anon_key']!
  );

  runApp(MyApp());
}

DotEnv initEnvVars() {
  var env = DotEnv(includePlatformEnvironment: true)..load();
  if (!env.isEveryDefined([
    'supabase_url', 
    'supabase_anon_key', 
    'api_base_url', 
    'google_client_id', 
    'google_client_secret'
  ])) {
    throw 'Not all required env vars were detected';
  }
  return env;
}

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

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with TrayListener, SystemTrayMixin {
  @override
  void initState() {
    super.initState();
    _setupAuthListener();
  }

  void _setupAuthListener() {
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (mounted) {
        AppRouter.router.refresh();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Calendai',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      routerConfig: AppRouter.router,
      debugShowCheckedModeBanner: false,
    );
  }
}