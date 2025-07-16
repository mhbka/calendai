import 'package:dotenv/dotenv.dart';
import 'package:flutter/material.dart';
import 'package:namer_app/init.dart';
import 'package:namer_app/mixins/system_tray.dart';
import 'package:namer_app/mixins/window_manager.dart';
import 'package:namer_app/router.dart'; 
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:uuid/uuid.dart';
import 'package:window_manager/window_manager.dart';

/// The env vars for the app.
late final DotEnv envVars;

/// The UUID generator for the app.
final Uuid uuid = Uuid();

void main() async {
  envVars = initEnvVars();  
  await initDeps();
  await initSystemTray();
  await initWindowSettings();

  await Supabase.initialize(
    url: envVars['supabase_url']!,
    anonKey: envVars['supabase_anon_key']!
  );

  runApp(App());
}

class App extends StatefulWidget {
  @override
  _AppState createState() => _AppState();
}

class _AppState extends State<App> with TrayListener, WindowListener, SystemTrayMixin, WindowManagerMixin {
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
    Size screenSize = MediaQuery.of(context).size;
    double width = screenSize.width;
    double height = screenSize.height;
    print("$width x $height");

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