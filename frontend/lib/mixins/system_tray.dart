import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:namer_app/main.dart';
import 'package:namer_app/models/calendar_event.dart';
import 'package:namer_app/router.dart';
import 'package:namer_app/services/notification_service.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

/// Mixin that provides system tray functionality to widgets
mixin SystemTrayMixin<T extends StatefulWidget> on State<T>, TrayListener {
  @override
  void initState() {
    super.initState();
    trayManager.addListener(this);
  }

  @override
  void dispose() {
    trayManager.removeListener(this);
    super.dispose();
  }

  @override
  void onTrayIconMouseDown() {
    print('Tray icon clicked');
    trayManager.popUpContextMenu();
  }

  @override
  void onTrayIconRightMouseDown() {
    print('Tray icon right clicked');
    trayManager.popUpContextMenu();
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    switch (menuItem.key) {
      case 'show_window':
        _showWindow();
      case 'hide_window':
        _hideWindow();
      case 'say_hello':
        _sayHello();
      case 'show_ai_event':
        _goToAddAIEvent();
      case 'quit':
        _quitApp();
    }
  }

  Future<void> _showWindow() async {
    await windowManager.show();
    await windowManager.focus();
  }

  Future<void> _hideWindow() async {
    await windowManager.hide();
  }

  Future<void> _sayHello() async {
    var event = CalendarEvent(
      id: uuid.v4(), 
      title: 'Calendai says...', 
      description: 'hello!', 
      startTime: DateTime.now(), 
      endTime: DateTime.now()
    );
    await NotificationService.debugNotif(event);
  }

  Future<void> _goToAddAIEvent() async {
    await windowManager.show();
    AppRouter.router.go('/add_ai_event');
  }

  Future<void> _quitApp() async {
    await windowManager.close();
  }

  /// Navigate to a specific route using GoRouter
  void navigateToRoute(String route) {
    if (mounted) {
      context.go(route);
    }
  }
}