

import 'package:flutter/material.dart';
import 'package:namer_app/models/recurring_event_group.dart';

class RecurringEventsGroupCard extends StatelessWidget {
  final RecurringEventGroup group;

  const RecurringEventsGroupCard({Key? key, required this.group}) : super(key: key);

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
                          '${group.recurringEvents} recurring event${group.recurringEvents == 1 ? '' : 's'}',
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