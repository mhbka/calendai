import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:namer_app/models/recurring_event.dart';
import 'package:namer_app/models/recurring_event_group.dart';
import 'package:namer_app/pages/base_page.dart';
import 'package:namer_app/widgets/recurring_events_group_card.dart';

class RecurringEventsPage extends StatefulWidget {
  const RecurringEventsPage({Key? key}) : super(key: key);

  @override
  State<RecurringEventsPage> createState() => _RecurringEventsPageState();
}

class _RecurringEventsPageState extends State<RecurringEventsPage> {
  // Sample data - replace with your actual data source
  List<RecurringEventGroup> recurringEventGroups = [
    RecurringEventGroup(
      name: "Ungrouped",
      description: null,
      color: Colors.grey,
      isActive: true,
      startDate: null,
      endDate: null,
      recurringEvents: [
        RecurringEvent(name: "Daily Standup"),
        RecurringEvent(name: "Weekly Review"),
      ],
    ),
    RecurringEventGroup(
      name: "Work Meetings",
      description: "All work-related recurring meetings",
      color: Colors.blue,
      isActive: true,
      startDate: DateTime(2024, 1, 1),
      endDate: DateTime(2024, 12, 31),
      recurringEvents: [
        RecurringEvent(name: "Team Meeting"),
        RecurringEvent(name: "Client Check-in"),
        RecurringEvent(name: "Project Review"),
      ],
    ),
    RecurringEventGroup(
      name: "Personal",
      description: "Personal recurring events and reminders",
      color: Colors.green,
      isActive: true,
      startDate: DateTime(2024, 1, 1),
      endDate: null,
      recurringEvents: [
        RecurringEvent(name: "Gym Session"),
        RecurringEvent(name: "Grocery Shopping"),
      ],
    ),
    RecurringEventGroup(
      name: "Family Events",
      description: "Family gatherings and activities",
      color: Colors.orange,
      isActive: false,
      startDate: DateTime(2024, 3, 1),
      endDate: DateTime(2024, 11, 30),
      recurringEvents: [
        RecurringEvent(name: "Sunday Dinner"),
      ],
    ),
  ];

  Widget _buildMainArea() {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: recurringEventGroups.length,
      itemBuilder: (context, index) {
        final group = recurringEventGroups[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: RecurringEventsGroupCard(group: group),
        );
      },
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
        child: const Icon(Icons.add),
      ),
    );
  }
}