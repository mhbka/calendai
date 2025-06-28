import 'dart:ui';
import 'package:dotenv/dotenv.dart';
import 'package:flutter/material.dart';
import 'package:namer_app/init.dart';
import 'package:namer_app/pages/calendar_page.dart';
import 'package:namer_app/services/notification_service.dart';
import 'package:namer_app/mixins/system_tray.dart'; 
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:uuid/uuid.dart';
import 'pages/login_page.dart';

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

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Calendai',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MainState(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MainState extends StatefulWidget {
  @override
  _MainStateState createState() => _MainStateState();
}

class _MainStateState extends State<MainState> with TrayListener, SystemTrayMixin {
  @override
  void initState() {
    super.initState();
    _checkAuthState();
  }

  void _checkAuthState() {
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