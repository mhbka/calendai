import 'package:flutter/material.dart';
import 'package:namer_app/models/calendar_event.dart';
import 'package:namer_app/widgets/event_dialog.dart';

/// A card for displaying, editing, and deleting a calendar event.
class EventCard extends StatelessWidget {
  final CalendarEvent event;
  final Function(CalendarEvent) onSubmitEdit;
  final VoidCallback onSubmitDelete;

  EventCard({
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
        height: 140, // Fixed height for equal heights
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
        _buildEditButton(context),
        SizedBox(width: 8),
        _buildDeleteButton(context)
      ],
    );
  }

  Widget _buildEditButton(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () async {
        await showDialog(
          context: context, 
          builder: (dialogContext) => EventDialog(event: event, onSubmit: onSubmitEdit)
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
            title: Text("Delete"),
            content: Text("Are you sure you want to delete this event?"),
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
              _formatDateRange(event.startTime, event.endTime),
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
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