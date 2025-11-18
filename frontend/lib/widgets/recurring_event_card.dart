import 'package:flutter/material.dart';
import 'package:calendai/models/recurring_event.dart';
import 'package:calendai/utils/recurrence_rrule_conversions.dart';
import 'package:calendai/widgets/recurring_event_dialog.dart';

class RecurringEventCard extends StatelessWidget {
  final RecurringEvent event;
  final Function(RecurringEvent) onSubmitEdit;
  final VoidCallback onSubmitDelete;

  RecurringEventCard({
    super.key, 
    required this.onSubmitEdit,
    required this.onSubmitDelete,
    required this.event
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      child: _buildCardBody(context)
    );
  }

  Widget _buildCardBody(BuildContext context) {
    return SizedBox(
        height: 140,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildColorIndicator(),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(context),
                    const SizedBox(height: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDescription(context),
                          _buildDateRange(context),
                          _buildRecurrenceDescription(context)
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
  }

  Widget _buildColorIndicator() {
    return Container(
      width: 6,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(4),
          bottomLeft: Radius.circular(4),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            event.title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        _buildStatusBadge(),
        SizedBox(width: 8),
        _buildEditButton(context),
        SizedBox(width: 8),
        _buildDeleteButton(context)
      ],
    );
  }

  Widget _buildStatusBadge() {
    Color color; 
    String text;
    if (event.isActive) {
      color = Colors.green;
      text = 'Active';
    }
    else {
      color = Colors.red;
      text = 'Inactive';
    }
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildEditButton(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () async {
        await showDialog(
          context: context, 
          builder: (dialogContext) => RecurringEventDialog(
            currentEvent: event,
            onSubmit: onSubmitEdit,
          )
        );
      },
      label: Text("Edit"),
      icon: Icon(Icons.edit),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildDeleteButton(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text("Delete group"),
            content: Text("Are you sure you want to delete this group and all its events? This action is irreversible."),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text("Back"),
              ),
              ElevatedButton(
                onPressed: onSubmitDelete,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: Text("Delete"),
              ),
            ],
          ),
        );
      },
      icon: Icon(Icons.delete),
      label: Text("Delete"),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildDescription(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        event.description ?? "-",
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Colors.grey[600],
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildDateRange(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(
            Icons.date_range,
            size: 16,
            color: Colors.grey[600],
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              _formatDateRange(event.recurrenceStart, event.recurrenceEnd),
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecurrenceDescription(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.event_repeat,
          size: 16,
          color: Colors.grey[600],
        ),
        const SizedBox(width: 4),
        Text(
          getEventRecurrence(event).describeRecurrence(),
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  String _formatDateRange(DateTime? startDate, DateTime? endDate) {
    if (startDate == null && endDate == null) return '';
    
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