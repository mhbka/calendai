import 'package:flutter/material.dart';

import 'package:calendai/controllers/recurring_event_groups_controller.dart';
import 'package:calendai/pages/base_page.dart';
import 'package:calendai/utils/alerts.dart';
import 'package:calendai/widgets/recurring_event_group_dialog.dart';
import 'package:calendai/widgets/recurring_events_group_card.dart';

class RecurringEventGroupsPage extends StatefulWidget {
  const RecurringEventGroupsPage({Key? key}) : super(key: key);

  @override
  State<RecurringEventGroupsPage> createState() => _RecurringEventGroupsPageState();
}

class _RecurringEventGroupsPageState extends State<RecurringEventGroupsPage> {
  final RecurringEventGroupsController _controller = RecurringEventGroupsController.instance;

  @override
  void initState() {
    super.initState();
    _controller.loadGroups().catchError((err) {
      if (mounted) Alerts.showErrorSnackBar(context, "Failed to load groups: $err. Please try again later.");
    });
    _controller.addListener(() {
      if (mounted) setState(() {});
    });
  }

  Widget _buildMainArea() {
    return RefreshIndicator(
      onRefresh: () async {
        await _controller.loadGroups();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: _controller.groups.length,
        itemBuilder: (context, index) {
          final group = _controller.groups[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: RecurringEventsGroupCard(group: group),
          );
        },
      ),
    );
  }

  Widget _buildFloatingActions() {
    if (_controller.groups.isEmpty) {
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
          backgroundColor: Colors.deepPurple,
          label: Text("Create a new group", style: TextStyle(color: Colors.white)),
        );
    } 
  }

  @override
  Widget build(BuildContext context) {
    return BasePage(
      title: "Recurring event groups",
      body: _buildMainArea(),
      floatingActions: _buildFloatingActions(),
    );
  }
}