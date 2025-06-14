import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:namer_app/calendar_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  
  await Supabase.initialize(
    url: 'https://uclimmvvlknnuzuznalk.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVjbGltbXZ2bGtubnV6dXpuYWxrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDk0NzUzNDYsImV4cCI6MjA2NTA1MTM0Nn0.OhI7v75HMD7tlcQGo4DsG7r9W69Id-GP0Ula29CALi0',
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
      home: AuthWrapper(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class AuthWrapper extends StatefulWidget {
  @override
  _AuthWrapperState createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    _checkAuthState();
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