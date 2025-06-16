import 'dart:io';
import 'dart:ui';
import 'package:dotenv/dotenv.dart';
import 'package:flutter/material.dart';
import 'package:namer_app/pages/calendar_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tray_manager/tray_manager.dart';
import 'pages/login_page.dart';

/// The env vars for the program.
late final DotEnv envVars;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();

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
  if (!env.isEveryDefined(['supabase_url', 'supabase_anon_key', 'api_base_url'])) {
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
        key: 'exit_app',
        label: 'Exit App',
      ),
    ],
  );
  await trayManager.setContextMenu(menu);
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Calendai',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: AuthWrapper(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class AuthWrapper extends StatefulWidget {
  @override
  _AuthWrapperState createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> with TrayListener {
  @override
  void initState() {
    trayManager.addListener(this);
    super.initState();
    _checkAuthState();
  }

  @override
  void dispose() {
    trayManager.removeListener(this);
    super.dispose();
  }

  @override
  void onTrayIconMouseDown() {
    print('test');
    trayManager.popUpContextMenu();
  }

  @override
  void onTrayIconRightMouseDown() {
    print('test2');
    trayManager.popUpContextMenu();
  }

  void _checkAuthState() {
    // Listen to auth state changes
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = Supabase.instance.client.auth.currentSession;
    
    if (session != null) {
      return CalendarPage();
    } else {
      return LoginPage();
    }
  }
}