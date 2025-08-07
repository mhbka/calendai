import 'package:flutter/material.dart';
import 'package:namer_app/controllers/recurring_events_controller.dart';
import 'package:namer_app/models/recurring_event.dart';
import 'package:namer_app/utils/alerts.dart';
import 'package:namer_app/utils/recurrence_rrule_conversions.dart';
import 'package:namer_app/widgets/recurrence_input.dart';
import 'package:rrule/rrule.dart';

/// Dialog for creating a new recurring event/updating a selected event.
class RecurringEventDialog extends StatefulWidget {
  final RecurringEvent? currentEvent;

  const RecurringEventDialog({
    Key? key,
    this.currentEvent,
  }) : super(key: key);

  @override
  _RecurringEventDialogState createState() => _RecurringEventDialogState();
}

class _RecurringEventDialogState extends State<RecurringEventDialog> {
  final RecurringEventsController _controller = RecurringEventsController.instance;
  late RecurrenceInputController _recurrenceInputController;
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  
  bool _isActive = true;
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();

    _titleController = TextEditingController(text: widget.currentEvent?.title ?? '');

    _descriptionController = TextEditingController(text: widget.currentEvent?.description ?? '');
    if (widget.currentEvent != null) {
      _isActive = widget.currentEvent!.isActive;
      RecurrenceData currentEventRRule = getEventRecurrence(widget.currentEvent!);
      _recurrenceInputController = RecurrenceInputController(initialData: currentEventRRule);
    }
    else {
      _recurrenceInputController = RecurrenceInputController();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  bool get _isEditing => widget.currentEvent != null;

  void _save() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_endDate != null && _startDate.isAfter(_endDate!)) {
      _showErrorDialog('Start date must be before end date');
      return;
    }
    
    RecurringEvent event;
    if (_isEditing) {
      event = RecurringEvent(
        id: widget.currentEvent!.id,
        groupId: _controller.currentGroup?.id,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty 
            ? null 
            : _descriptionController.text.trim(),
        isActive: _isActive,
        recurrenceStart: _startDate,
        recurrenceEnd: _endDate,
        rrule: _recurrenceInputController.getRRule().toString(),
        eventDurationSeconds: _recurrenceInputController.getEventDurationSeconds()
      );
    } else {
      event = RecurringEvent(
        id: "-1",
        groupId: _controller.currentGroup?.id,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty 
            ? null 
            : _descriptionController.text.trim(),
        isActive: _isActive,
        recurrenceStart: _startDate,
        recurrenceEnd: _endDate,
        rrule: _recurrenceInputController.getRRule().toString(),
        eventDurationSeconds: _recurrenceInputController.getEventDurationSeconds()
      );
    }
    _controller.saveEvent(event, !_isEditing)
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
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
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

  Widget _buildRecurrenceInput() {
    return RecurrenceInput(controller: _recurrenceInputController);
  }

  Widget _buildActiveSwitch() {
    return Row(
      spacing: 8,
      children: [
        const Text('Active: '),
        Switch(
          value: _isActive,
          onChanged: (value) {
            setState(() {
              _isActive = value;
            });
          },
        ),
        Tooltip(
          message: 'When inactive, events in this group will be disabled by default',
          child: Icon(Icons.help_outline, size: 16, color: Colors.grey),
        ),
      ],
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
        child: Text(_isEditing ? 'Update' : 'Add'),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEditing ? 'Edit event' : 'Create a new event'),
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
              _buildActiveSwitch(),
              const SizedBox(height: 16),
              _buildRecurrenceInput()
            ],
          ),
        ),
      ),
      actions: _buildDialogActions(),
    );
  }
}