import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:namer_app/controllers/recurring_event_groups_controller.dart';
import 'package:namer_app/models/recurring_event_group.dart';
import 'package:namer_app/pages/base_page.dart';
import 'package:namer_app/widgets/recurring_events_group_card.dart';

class RecurringEventGroupsPage extends StatefulWidget {
  const RecurringEventGroupsPage({Key? key}) : super(key: key);

  @override
  State<RecurringEventGroupsPage> createState() => _RecurringEventGroupsPageState();
}

class _RecurringEventGroupsPageState extends State<RecurringEventGroupsPage> {
  final RecurringEventGroupsController _controller = RecurringEventGroupsController.instance;

  // Sample data - replace with your actual data source
  List<RecurringEventGroup> recurringEventGroups = [
    RecurringEventGroup(
      name: "Work Meetings",
      id: "2",
      description: "All work-related recurring meetings",
      color: Colors.blue,
      isActive: true,
      startDate: DateTime(2024, 1, 1),
      endDate: DateTime(2024, 12, 31),
      recurringEvents: 3,
    ),
    RecurringEventGroup(
      name: "Personal",
      id: "3",
      description: "Personal recurring events and reminders",
      color: Colors.green,
      isActive: true,
      startDate: DateTime(2024, 1, 1),
      endDate: null,
      recurringEvents: 1,
    ),
    RecurringEventGroup(
      name: "Uncategorized Events",
      id: "1",
      description: "Events not assigned to any specific group",
      color: Colors.grey,
      isActive: true,
      startDate: null,
      endDate: null,
      recurringEvents: 2,
    ),
  ];

  // Filter out inactive groups with 0 events
  List<RecurringEventGroup> get _filteredGroups {
    return recurringEventGroups.where((group) {
      return !(group.recurringEvents == 0 && !(group.isActive ?? false));
    }).toList();
  }

  Widget _buildMainArea() {
    return RefreshIndicator(
      onRefresh: () async {
        // Add refresh functionality here
        await Future.delayed(const Duration(milliseconds: 500));
        setState(() {
          // Refresh data
        });
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: _filteredGroups.length,
        itemBuilder: (context, index) {
          final group = _filteredGroups[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: RecurringEventsGroupCard(group: group),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BasePage(
      title: "Recurring events",
      body: _buildMainArea(),
      floatingActions: FloatingActionButton(
        onPressed: () {
          // Add new group functionality
        },
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }
}