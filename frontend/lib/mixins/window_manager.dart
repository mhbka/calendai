import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

mixin WindowManagerMixin<T extends StatefulWidget> on State<T> implements WindowListener {
  @override
  void initState() {
    super.initState();
    _initWindowManager();
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  void _initWindowManager() async {
    windowManager.addListener(this);
    await windowManager.setPreventClose(true);
  }

  @override
  void onWindowClose() async {
    bool isPreventClose = await windowManager.isPreventClose();
    if (isPreventClose) {
      // TODO: hide or minimize the app?
      await windowManager.minimize();
    }
  }

  // non-overridden 
  
  @override
  void onWindowEvent(String eventName) {}

  @override
  void onWindowFocus() {}

  @override
  void onWindowBlur() {}

  @override
  void onWindowMaximize() {}

  @override
  void onWindowUnmaximize() {}

  @override
  void onWindowMinimize() {}

  @override
  void onWindowRestore() {}

  @override
  void onWindowResize() {}

  @override
  void onWindowMove() {}

  @override
  void onWindowEnterFullScreen() {}

  @override
  void onWindowLeaveFullScreen() {}

  // Helper method to actually close the app
  Future<void> closeApp() async {
    await windowManager.setPreventClose(false);
    await windowManager.close();
  }

  // Helper method to hide instead of minimize
  Future<void> hideOnClose() async {
    await windowManager.hide();
  }
}