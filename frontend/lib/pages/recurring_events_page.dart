import 'package:flutter/material.dart';
import 'package:namer_app/constants.dart';
import 'package:namer_app/controllers/recurring_events_controller.dart';
import 'package:namer_app/pages/base_page.dart';
import 'package:namer_app/utils/alerts.dart';
import 'package:namer_app/widgets/recurring_event_card.dart';
import 'package:namer_app/widgets/recurring_event_group_dialog.dart';

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
    _controller.resetGroup();
    _controller.setGroupLoadEvents(widget.groupId).catchError((err) {
      if (mounted) Alerts.showErrorSnackBar(context, "Failed to load groups: $err. Please try again later.");
    });
    _controller.addListener(() {
      if (mounted) setState(() {});
    });
  }

  Widget _buildMainArea() {
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
            child: RecurringEventCard(event: event),
          );
        },
      ),
    );
  }

  Widget _buildFloatingActions() {
    if (_controller.events.isEmpty) {
      return SizedBox.shrink();
    }
    else {
      return FloatingActionButton.extended(
          onPressed: () async {
            await showDialog(
              context: context, 
              builder: (dialogContext) => RecurringEventGroupDialog()
            );
          },
          heroTag: "recurring_event_group_create",
          icon: Icon(Icons.add, color: Colors.white),
          backgroundColor: CalendarConstants.primaryColor,
          label: Text("Create a new group", style: CalendarConstants.whiteTextStyle),
        );
    } 
  }

  @override
  Widget build(BuildContext context) {
    return BasePage(
      title: "Recurring events - ${_controller.currentGroup?.name ?? "Ungrouped"}",
      body: _buildMainArea(),
      floatingActions: _buildFloatingActions(),
    );
  }
}