import 'package:flutter/material.dart';
import 'package:calendai/controllers/ai_event_controller.dart';
import 'package:calendai/models/calendar_event.dart';
import 'package:calendai/models/recurring_event.dart';
import 'package:calendai/models/recurring_event_group.dart';
import 'package:calendai/utils/alerts.dart';
import 'package:calendai/widgets/event_card.dart';
import 'package:calendai/widgets/event_dialog.dart';
import 'package:calendai/widgets/recurring_event_card.dart';
import 'package:calendai/widgets/recurring_event_dialog.dart';
import 'package:calendai/widgets/recurring_event_group_dialog.dart';
import 'package:calendai/widgets/recurring_events_group_card.dart';

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

  /// Build the section for the recurring event group.
  Widget _buildRecurringEventGroupSection(RecurringEventGroup? group) {
    Widget groupCard;
    if (group == null) {
      groupCard = _buildEmptySection("No group has been set. Click here to create one.");
    } else {
      groupCard = RecurringEventsGroupCard(group: group);
    }
    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            'Recurring Event Group', 
            Icons.folder,
            () => showDialog(
              builder: (context) => RecurringEventGroupDialog(), // TODO: add callback for this dialog to set the group instead
              context: context
            )
          ),
          groupCard,
          const SizedBox(height: 16),
        ],
      ),
    );
  }
  
  /// Build the section for calendar events.
  Widget _buildEventsSection(List<CalendarEvent> events) {
    Widget eventList;
    if (events.isEmpty) {
      eventList = _buildEmptySection("There are no events. Click here to create one.");
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
          _buildSectionHeader(
            'Events',
            Icons.event,
            () => showDialog(
              context: context, 
              builder: (context) => EventDialog(
                onSubmit: (event) {
                  _controller.addEvent(event);
                  Navigator.pop(context);
                },
              )
            )
          ),
          eventList,
          const SizedBox(height: 16),
        ],
      ),
    );
  }
  
  /// Build the section for recurring events.
  Widget _buildRecurringEventsSection(List<RecurringEvent> events) {
    Widget eventList;
    if (events.isEmpty) {
      eventList = _buildEmptySection("There are no recurring events. Click here to create one.");
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
          _buildSectionHeader(
            'Recurring Events', 
            Icons.repeat,
            () => showDialog(
              context: context,
              builder: (context) => RecurringEventDialog(
                onSubmit: (event) {
                  _controller.addRecurringEvent(event);
                  Navigator.pop(context);
                }
              )
            )
          ),
          eventList,
          const SizedBox(height: 16),
        ],
      ),
    );
  }
  
  /// Build the header for a section, including the 'Add' button.
  Widget _buildSectionHeader(String title, IconData icon, VoidCallback onAdd) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 20),
          SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(width: 16),
          FilledButton(
            onPressed: onAdd,
            child: Text('Add'),
          )
        ],
      ),
    );
  }

  /// Build the section placeholder for if it's empty.
 Widget _buildEmptySection(String placeholderText) {
  return Card(
    elevation: 2,
    margin: EdgeInsets.zero,
    child: SizedBox(
      height: 140,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: 6,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(4)),
            ),
          ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.cancel, size: 32, color: Colors.grey[400]),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    placeholderText,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
}