import 'package:flutter/material.dart';
import 'package:namer_app/models/calendar_event.dart';

class EventDialog extends StatefulWidget {
  final CalendarEvent? event;
  final DateTime? selectedDay;
  final Function(CalendarEvent?, String, String, String?, DateTime, DateTime) onSave;

  const EventDialog({
    Key? key,
    this.event,
    this.selectedDay,
    required this.onSave,
  }) : super(key: key);

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
    
    _startTime = event?.startTime ?? widget.selectedDay!.add(Duration(hours: 9));
    _endTime = event?.endTime ?? widget.selectedDay!.add(Duration(hours: 10));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  bool get _isEditing => widget.event != null;

  Future<void> _selectStartTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _startTime,
      firstDate: DateTime.now().subtract(Duration(days: 365)),
      lastDate: DateTime.now().add(Duration(days: 365)),
    );
    
    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_startTime),
      );
      
      if (time != null) {
        setState(() {
          _startTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
          if (_endTime.isBefore(_startTime)) {
            _endTime = _startTime.add(Duration(hours: 1));
          }
        });
      }
    }
  }

  Future<void> _selectEndTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _endTime,
      firstDate: _startTime,
      lastDate: DateTime.now().add(Duration(days: 365)),
    );
    
    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_endTime),
      );
      
      if (time != null) {
        setState(() {
          _endTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
        });
      }
    }
  }

  void _save() {
    if (_titleController.text.isEmpty) return;
    
    widget.onSave(
      widget.event,
      _titleController.text,
      _descriptionController.text,
      _locationController.text.isEmpty ? null : _locationController.text,
      _startTime,
      _endTime,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEditing ? 'Edit Event' : 'Add Event'),
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
            ListTile(
              title: Text('Start Time'),
              subtitle: Text('${_startTime.day}/${_startTime.month}/${_startTime.year} ${_startTime.hour}:${_startTime.minute.toString().padLeft(2, '0')}'),
              trailing: Icon(Icons.edit),
              onTap: _selectStartTime,
            ),
            ListTile(
              title: Text('End Time'),
              subtitle: Text('${_endTime.day}/${_endTime.month}/${_endTime.year} ${_endTime.hour}:${_endTime.minute.toString().padLeft(2, '0')}'),
              trailing: Icon(Icons.edit),
              onTap: _selectEndTime,
            ),
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