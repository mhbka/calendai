import 'package:flutter/material.dart';

import 'package:namer_app/controllers/recurring_events_controller.dart';
import 'package:namer_app/models/recurring_event.dart';
import 'package:namer_app/pages/base_page.dart';
import 'package:namer_app/utils/alerts.dart';
import 'package:namer_app/widgets/recurring_event_card.dart';
import 'package:namer_app/widgets/recurring_event_dialog.dart';

class RecurringEventsPage extends StatefulWidget {
  final String? groupId;
  const RecurringEventsPage({super.key, this.groupId});

  @override
  State<RecurringEventsPage> createState() => _RecurringEventsPageState();
}

class _RecurringEventsPageState extends State<RecurringEventsPage> {
  final RecurringEventsController _controller = RecurringEventsController.instance;

  @override
  void initState() {
    super.initState();
    _controller.setGroupLoadEvents(widget.groupId).catchError((err) {
      if (mounted) Alerts.showErrorSnackBar(context, "Failed to load groups: $err. Please try again later.");
    });
    _controller.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return BasePage(
      title: "Recurring events - ${_controller.isLoading ? "" : _controller.currentGroup?.name ?? "Ungrouped"}",
      body: _controller.isLoading ? _buildLoading() : _buildMainArea(),
      floatingActions: _controller.events.isEmpty ? null : _buildAddEventButton(),
    );
  }

  Widget _buildMainArea() {
    if (_controller.events.isEmpty) {
      return Center(
        child: Container(
          margin: EdgeInsets.all(32),
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!, width: 1),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "There are no events in this group. To get started, create an event.",
                style: TextStyle(fontSize: 18),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),
              _buildAddEventButton(),
            ],
          ),
        ),
      );
    }
    else {
      return RefreshIndicator(
        onRefresh: () async {
          await _controller.loadEvents();
        },
        child: ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: _controller.events.length,
          itemBuilder: (context, index) {
            final event = _controller.events[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: RecurringEventCard(
                event: event,
                onSubmitEdit: _editEvent,
                onSubmitDelete: () => _deleteEvent(event.id ?? ''),
              ),
            );
          },
        ),
      );
    }
  }

  Widget _buildLoading() {
    return Center(child: CircularProgressIndicator());
  }

  Widget _buildAddEventButton() {
    return FloatingActionButton.extended(
        onPressed: () async {
          await showDialog(
            context: context, 
            builder: (dialogContext) => RecurringEventDialog(
              onSubmit: (newEvent) {
                _controller.saveEvent(newEvent, true)
                  .then((v) => {if (mounted) Navigator.pop(context)})
                  .catchError((err) async {
                    if (mounted) {
                      await Alerts.showErrorDialog(
                        context, 
                        "Error", 
                        "Failed to save the event: $err. Please try again later."
                      );
                    }
                    return <dynamic>{};
                  });
              },
            )
          );
        },
        heroTag: "recurring_event_create",
        icon: Icon(Icons.add, color: Colors.white),
        backgroundColor: Colors.deepPurple,
        label: Text("Create a new event", style: TextStyle(color: Colors.white)),
      );
  }

  /// Callback for deleting a recurring event.
  void _deleteEvent(String? eventId) {
    _controller.deleteEvent(eventId ?? '')
      .then((value) => {if (mounted) Navigator.pop(context)})
      .catchError((err) {
        if (mounted) {
          Alerts.showErrorDialog(
            context, 
            "Error", 
            "Failed to delete event: $err. Please try again later."
          );
        }
        return <dynamic>{}; // seems to be a quirk of Flutter; we need this to not crash
      });
  }

  /// Callback for submitting an edited recurring event.
  void _editEvent(RecurringEvent updatedEvent) {
    _controller.saveEvent(updatedEvent, false)
      .then((value) => {if (mounted) Navigator.pop(context)})
      .catchError((err) {
        if (mounted) {
          Alerts.showErrorDialog(
            context, 
            "Error", 
            "Failed to submit event: $err. Please try again later."
          );
        }
        return <dynamic>{}; // seems to be a quirk of Flutter; we need this to not crash
      });
  }
}