// lib/widgets/calendar_floating_actions.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:namer_app/constants.dart';

class CalendarFloatingActions extends StatelessWidget {
  final VoidCallback onAddEvent;
  final VoidCallback? onAddWithAI;

  const CalendarFloatingActions({
    Key? key,
    required this.onAddEvent,
    this.onAddWithAI,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: CalendarConstants.floatingButtonPadding,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: CalendarConstants.buttonSpacing,
        children: [
          FloatingActionButton.extended(
            onPressed: onAddWithAI ?? () => _handleAddWithAI(context),
            heroTag: "ai_add",
            backgroundColor: CalendarConstants.primaryColor,
            icon: Icon(Icons.auto_awesome, color: Colors.white),
            label: Text(
              CalendarConstants.addWithAILabel,
              style: CalendarConstants.whiteTextStyle,
            ),
          ),
          FloatingActionButton.extended(
            onPressed: onAddEvent,
            heroTag: "normal_add",
            icon: Icon(Icons.add),
            label: Text(CalendarConstants.addEventLabel),
          ),
        ],
      ),
    );
  }

  void _handleAddWithAI(BuildContext context) {
    context.push('/add_ai_event');
  }
}