import 'dart:async';

import 'package:flutter/material.dart';
import 'package:namer_app/init.dart';
import 'package:namer_app/mixins/system_tray.dart';
import 'package:namer_app/mixins/window_manager.dart';
import 'package:namer_app/router.dart'; 
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:uuid/uuid.dart';
import 'package:window_manager/window_manager.dart';

/// Defines the env variables required for the app.
class EnvVars {
  String envType;
  String supabaseUrl;
  String supabaseAnonKey;
  String apiBaseUrl;
  EnvVars(this.envType, this.supabaseUrl, this.supabaseAnonKey, this.apiBaseUrl);
}

/// The env variables for the app.
late final EnvVars envVars;

/// The UUID generator for the app.
final Uuid uuid = Uuid();

void main() async {
  envVars = initEnvVars();  
  await initDeps();
  await initWindowSettings();
  
  runZonedGuarded(() {
    runApp(App());
  }, 
  (error, stackTrace) {
    print("Caught an uncaught exception! $error");
  });
}

class App extends StatefulWidget {
  @override
  _AppState createState() => _AppState();
}

class _AppState extends State<App> with 
  TrayListener, 
  WindowListener, 
  SystemTrayMixin, 
  WindowManagerMixin 
{
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
    },
      onError: (error) => print("Error from auth: $error")
    );
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