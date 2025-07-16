import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class RecurringEventsPage extends StatefulWidget {
  const RecurringEventsPage({Key? key}) : super(key: key);

  @override
  State<RecurringEventsPage> createState() => _RecurringEventsPageState();
}

class _RecurringEventsPageState extends State<RecurringEventsPage> {
  // Sample data - replace with your actual data source
  List<EventGroup> eventGroups = [
    EventGroup(
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
    EventGroup(
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
    EventGroup(
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
    EventGroup(
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recurring Events'),
        leading: IconButton(
          onPressed: () => context.pop(), 
          icon: Icon(Icons.arrow_back)
        ),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: eventGroups.length,
        itemBuilder: (context, index) {
          final group = eventGroups[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: EventGroupCard(group: group),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Add new group functionality
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class EventGroupCard extends StatelessWidget {
  final EventGroup group;

  const EventGroupCard({Key? key, required this.group}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Color indicator (post-it style)
            Container(
              width: 6,
              decoration: BoxDecoration(
                color: group.color,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  bottomLeft: Radius.circular(4),
                ),
              ),
            ),
            // Main content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header row with name and status
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            group.name,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: group.isActive ? Colors.green : Colors.red,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            group.isActive ? 'Active' : 'Inactive',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    
                    // Description
                    if (group.description != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          group.description!,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    
                    // Date range
                    if (group.startDate != null || group.endDate != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Icon(
                              Icons.date_range,
                              size: 16,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _formatDateRange(group.startDate, group.endDate),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    
                    // Recurring events count
                    Row(
                      children: [
                        Icon(
                          Icons.event_repeat,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${group.recurringEvents.length} recurring event${group.recurringEvents.length == 1 ? '' : 's'}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateRange(DateTime? startDate, DateTime? endDate) {
    if (startDate == null && endDate == null) return '';
    
    final dateFormat = 'MMM d, yyyy';
    
    if (startDate != null && endDate != null) {
      return '${_formatDate(startDate)} - ${_formatDate(endDate)}';
    } else if (startDate != null) {
      return 'From ${_formatDate(startDate)}';
    } else {
      return 'Until ${_formatDate(endDate!)}';
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

// Data models
class EventGroup {
  final String name;
  final String? description;
  final Color color;
  final bool isActive;
  final DateTime? startDate;
  final DateTime? endDate;
  final List<RecurringEvent> recurringEvents;

  EventGroup({
    required this.name,
    this.description,
    required this.color,
    required this.isActive,
    this.startDate,
    this.endDate,
    required this.recurringEvents,
  });
}

class RecurringEvent {
  final String name;

  RecurringEvent({required this.name});
}