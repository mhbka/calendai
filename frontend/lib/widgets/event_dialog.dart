import 'package:flutter/material.dart';
import 'package:calendai/models/calendar_event.dart';
import 'package:calendai/widgets/datetime_picker.dart';

/// Dialog for creating a new event/updating a selected event.
class EventDialog extends StatefulWidget {
  final CalendarEvent? event;
  final Function(CalendarEvent) onSubmit;
  final DateTime? selectedDay;

  EventDialog({
    super.key,
    this.event,
    this.selectedDay,
    required this.onSubmit
  });

  @override
  _EventDialogState createState() => _EventDialogState();
}

class _EventDialogState extends State<EventDialog> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _locationController;
  late DateTime _startTime;
  late DateTime _endTime;

  @override
  void initState() {
    super.initState();
    final event = widget.event;
    _titleController = TextEditingController(text: event?.title ?? '');
    _descriptionController = TextEditingController(text: event?.description ?? '');
    _locationController = TextEditingController(text: event?.location ?? '');
    
    _startTime = event?.startTime ?? 
      widget.selectedDay ?? 
      DateTime.now();
    _endTime = event?.endTime ?? 
      widget.selectedDay?.add(Duration(hours: 1)) ?? 
      DateTime.now().add(Duration(hours: 1));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  bool get _isEditing => widget.event != null;

  void _save() {
    if (_titleController.text.isEmpty) return;

    CalendarEvent event;
    if (widget.event != null) {
      event = CalendarEvent(
        id: widget.event!.id, 
        title: _titleController.text, 
        description: _descriptionController.text,
        location: _locationController.text,
        startTime: _startTime, 
        endTime: _endTime
      );
    }
    else {
      event = CalendarEvent(
        id: '-1', 
        title: _titleController.text, 
        description: _descriptionController.text,
        location: _locationController.text,
        startTime: _startTime, 
        endTime: _endTime
      );
    }

    widget.onSubmit(event);

    /*
    _controller.saveEvent(event, widget.event == null)
      .then((v) => {if (mounted) Navigator.pop(context)})
      .catchError((err) async {
        if (mounted)  {
          await Alerts.showErrorDialog(
            context, 
            "Error", 
            "Failed to save the event: $err. Please try again later."
          );
        }
        return <dynamic>{};
      });
    */
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEditing ? 'Edit event' : 'Create an event'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              decoration: InputDecoration(labelText: 'Title'),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(labelText: 'Description'),
              maxLines: 3,
            ),
            SizedBox(height: 16),
            TextField(
              controller: _locationController,
              decoration: InputDecoration(labelText: 'Location (optional)'),
            ),
            SizedBox(height: 16),
            DateTimePicker(
              startTime: _startTime,
              endTime: _endTime,
              onDateTimesChanged: (start, end) {
                setState(() {
                  _startTime = start;
                  _endTime = end;
                });
              }
            )
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _save,
          child: Text(_isEditing ? 'Update' : 'Add'),
        ),
      ],
    );
  }
}