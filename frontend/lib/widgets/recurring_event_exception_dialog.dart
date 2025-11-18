import 'package:flutter/material.dart';
import 'package:calendai/controllers/recurring_events_controller.dart';
import 'package:calendai/models/recurring_calendar_event.dart';
import 'package:calendai/models/recurring_event_exception.dart';
import 'package:calendai/utils/alerts.dart';
import 'package:calendai/widgets/datetime_picker.dart';

/// Dialog for creating/updating a 'modify' recurring event exception.
class RecurringEventExceptionDialog extends StatefulWidget {
  final RecurringCalendarEvent event;

  const RecurringEventExceptionDialog({
    super.key,
    required this.event
  });

  @override
  _RecurringEventExceptionDialogState createState() => _RecurringEventExceptionDialogState();
}

class _RecurringEventExceptionDialogState extends State<RecurringEventExceptionDialog> {
  final RecurringEventsController _controller = RecurringEventsController.instance;
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _locationController;
  
  late DateTime _startTime;
  late DateTime _endTime;
  
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.event.title);
    _descriptionController = TextEditingController(text: widget.event.description);
    _locationController = TextEditingController(text: widget.event.location);
    _startTime = widget.event.startTime;
    _endTime = widget.event.endTime;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_startTime.isAfter(_endTime)) {
      Alerts.showErrorDialog(
        context, 
        "Error",
        "Start date must be before end date"
      );
      return;
    }
    _saveException();
  }

  /// Saves this dialog as an exception.
  void _saveException() {
    String? modifiedTitle;
    String? modifiedDescription;
    String? modifiedLocation;
    DateTime? modifiedStartTime;
    DateTime? modifiedEndTime;

    /*
    // TODO: using <Option<Option<_>> in the backend doesn't work because, if we use null here, the value is interpreted
    // TODO: as `Some(_)` and not `None`, meaning a single change will override the other values with null. Thus,
    // TODO: for now, an exception will store ALL METADATA VALUES of the event at the time. This means changes to the actual event's metadata
    // TODO: will not be reflected at all in modified exceptions.
    // TODO: Will think about how to solve this.
    if (_titleController.text.trim() != widget.event.title) {
      modifiedTitle = _titleController.text.trim();
    }
    {
      String? description = _descriptionController.text.trim().isEmpty 
        ? null 
        : _descriptionController.text.trim();
      if (description != widget.event.description) {
        modifiedDescription = description;
      }
    }
    {
      String? location = _locationController.text.trim().isEmpty 
        ? null 
        : _locationController.text.trim();
      if (location != widget.event.location) {
        modifiedLocation = location;
      }
    }
    */
    modifiedTitle = _titleController.text.trim();
    modifiedDescription = _descriptionController.text.trim();
    modifiedLocation = _locationController.text.trim();

    if (_startTime != widget.event.startTime) {
      modifiedStartTime = _startTime;
    }
    if (_endTime != widget.event.endTime) {
      modifiedEndTime = _endTime;
    }

    RecurringEventException exception = RecurringEventException(
      id: widget.event.exceptionId ?? '-1', 
      recurringEventId: widget.event.recurringEventId, 
      exceptionDate: widget.event.startTime, 
      exceptionType: RecurringEventExceptionType.modified,
      modifiedTitle: modifiedTitle,
      modifiedDescription: modifiedDescription,
      modifiedLocation: modifiedLocation,
      modifiedStartTime: modifiedStartTime,
      modifiedEndTime: modifiedEndTime
    );
    _controller.saveEventException(exception, widget.event.exceptionId == null)
      .then((v) {
        if (mounted) {Navigator.pop(context);}
        print("this is after the save");
      })
      .catchError((err) async {
        if (mounted)  {
          await Alerts.showErrorDialog(
            context, 
            "Error", 
            "Failed to save this recurring event's exception: $err. Please try again later."
          );
        }
      });
  }

  Widget _buildNameField() {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Name *',
              hintText: 'Enter event name',
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Name is required';
              }
              return null;
            },
          ),
        ),
        Tooltip(
          message: 'A unique name to identify this recurring event group',
          child: Icon(Icons.help_outline, size: 16, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildDescriptionField() {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              labelText: 'Description',
              hintText: 'Enter description (optional)',
            ),
            maxLines: 3,
          ),
        ),
        Tooltip(
          message: 'Optional description to provide more details about this event group',
          child: Icon(Icons.help_outline, size: 16, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildLocationField() {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: _locationController,
            decoration: const InputDecoration(
              labelText: 'Location',
              hintText: 'Enter location of the event (optional)',
            ),
            maxLines: 3,
          ),
        ),
        Tooltip(
          message: 'Optional location of this event',
          child: Icon(Icons.help_outline, size: 16, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildDatePicker() {
    return DateTimePicker(
      startTime: _startTime,
      endTime: _endTime,
      onDateTimesChanged: (start, end) {
        setState(() {
          print("$start, $end");
          _startTime = start;
          _endTime = end;
          print("$_startTime, $_endTime");
        }); 
      }
    );
  }

  List<Widget> _buildDialogActions() {
    return [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      ElevatedButton(
        onPressed: _save,
        child: Text('Save'),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.event.exceptionId != null ? 'Edit an exception' : 'Create an exception'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildNameField(),
              const SizedBox(height: 16),
              _buildDescriptionField(),
              const SizedBox(height: 16),
              _buildLocationField(),
              const SizedBox(height: 16),
              _buildDatePicker()
            ],
          ),
        ),
      ),
      actions: _buildDialogActions(),
    );
  }
}