// lib/widgets/calendar_app_bar.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:namer_app/constants.dart';
import 'package:namer_app/controllers/calendar_controller.dart';

class CalendarAppBar extends StatelessWidget implements PreferredSizeWidget {
  final CalendarController controller;
  final VoidCallback? onRefresh;
  final VoidCallback? onLogout;

  const CalendarAppBar({
    Key? key,
    required this.controller,
    this.onRefresh,
    this.onLogout,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text('Calendai'),
      actions: [
        IconButton(
          icon: Icon(Icons.refresh),
          onPressed: onRefresh ?? () => _handleRefresh(context),
        ),
        TextButton(
          onPressed: () => context.push('/recurring_events'),
          style: CalendarTheme.primaryButtonStyle,
          child: Text(
            CalendarConstants.viewRecurringEventsLabel,
            style: CalendarConstants.whiteTextStyle,
          ),
        ),
        TextButton(
          onPressed: onLogout ?? () => _handleLogout(context),
          child: Text(CalendarConstants.logoutLabel),
        ),
      ],
    );
  }

  Future<void> _handleRefresh(BuildContext context) async {
    try {
      await controller.loadEvents();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${CalendarConstants.failedToLoadMessage}: $e')),
      );
    }
  }

  void _handleLogout(BuildContext context) {
    // Implement logout logic here
    // For now, it's just a placeholder
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}