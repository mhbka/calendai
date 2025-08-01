import 'package:flutter/material.dart';
import 'package:namer_app/constants.dart';
import 'package:namer_app/controllers/recurring_event_groups_controller.dart';
import 'package:namer_app/models/recurring_event_group.dart';
import 'package:namer_app/pages/base_page.dart';
import 'package:namer_app/utils/alerts.dart';
import 'package:namer_app/widgets/recurring_event_group_dialog.dart';
import 'package:namer_app/widgets/recurring_events_group_card.dart';

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

  /// Update/create the group.
  Future<void> _saveGroup(RecurringEventGroup groupData, bool isNewGroup) async {
      await _controller.saveGroup(groupData, isNewGroup);
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
              builder: (dialogContext) => RecurringEventGroupDialog(
                onSave: _saveGroup,
                )
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
      title: "Recurring events",
      body: _buildMainArea(),
      floatingActions: _buildFloatingActions(),
    );
  }
}