import 'package:flutter/material.dart';
import 'package:tray_manager/tray_manager.dart';

/// Used for adding Windows system tray to the app.
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
        // Handle show window action
        break;
      // Add other menu item handlers here
    }
  }
}