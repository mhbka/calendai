import 'package:flutter/material.dart';
import 'package:namer_app/controllers/ai_event_controller.dart';
import 'package:namer_app/models/calendar_event.dart';
import 'package:namer_app/models/recurring_event.dart';
import 'package:namer_app/models/recurring_event_group.dart';
import 'package:namer_app/utils/alerts.dart';
import 'package:namer_app/widgets/event_card.dart';
import 'package:namer_app/widgets/recurring_event_card.dart';
import 'package:namer_app/widgets/recurring_events_group_card.dart';

/// A dialog for reviewing generated events produced by AI.
class GeneratedEventsDialog extends StatefulWidget {
  const GeneratedEventsDialog({super.key});

  @override
  State<GeneratedEventsDialog> createState() => _GeneratedEventsDialogState();
}

class _GeneratedEventsDialogState extends State<GeneratedEventsDialog> {
  final AddAIEventController _controller = AddAIEventController.instance;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Review Generated Events'),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildEventsSection(_controller.generatedEvents.events),
              _buildRecurringEventsSection(_controller.generatedEvents.recurringEvents),
              _buildRecurringEventGroupSection(_controller.generatedEvents.recurringEventGroup),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            _controller.saveGeneratedEvents()
              .then((v) {if (context.mounted) Navigator.pop(context);})
              .catchError((err) async {
                if (context.mounted) {
                  await Alerts.showErrorDialog(
                    context, 
                    "Error", 
                    "Failed to save the event: $err. Please try again later."
                  );
                }
              });
          },
          child: const Text('Submit'),
        ),
      ],
    );
  }

  Widget _buildRecurringEventGroupSection(RecurringEventGroup? group) {
    Widget groupCard;
    if (group == null) {
      groupCard = const Text("No group was set.");
    } else {
      groupCard = RecurringEventsGroupCard(group: group);
    }
    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Recurring Event Group', Icons.folder),
          groupCard,
          const SizedBox(height: 16),
        ],
      ),
    );
  }
  
  Widget _buildEventsSection(List<CalendarEvent> events) {
    Widget eventList;
    if (events.isEmpty) {
      eventList = const Text("No calendar events have been set.");
    } 
    else {
      eventList = ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: events.length,
        itemBuilder: (context, index) => EventCard(
          event: events[index],
          onSubmitDelete: () {
            _controller.deleteEvent(index);
            Navigator.pop(context);
          },
          onSubmitEdit: (editedEvent) {
            _controller.editEvent(index, editedEvent); 
            Navigator.pop(context);
          },
        ),
      );
    }
    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Events', Icons.event),
          eventList,
          const SizedBox(height: 16),
        ],
      ),
    );
  }
  
  Widget _buildRecurringEventsSection(List<RecurringEvent> events) {
    Widget eventList;
    if (events.isEmpty) {
      eventList = const Text("No recurring events have been set.");
    } 
    else {
      eventList = ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: events.length,
        itemBuilder: (context, index) => RecurringEventCard(
          event: events[index],
          onSubmitDelete: () => _controller.deleteRecurringEvent(index),
          onSubmitEdit: (editedEvent) => _controller.editRecurringEvent(index, editedEvent),
        ),
      );
    }
    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Recurring Events', Icons.repeat),
          eventList,
          const SizedBox(height: 16),
        ],
      ),
    );
  }
  
  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}