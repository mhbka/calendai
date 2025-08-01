import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:namer_app/controllers/recurring_event_groups_controller.dart';
import 'package:namer_app/models/recurring_event_group.dart';
import 'package:namer_app/utils/alerts.dart';
import 'package:namer_app/widgets/recurrence_input.dart';

/// Dialog for creating a new recurring event group/updating a selected group.
class RecurringEventGroupDialog extends StatefulWidget {
  final RecurringEventGroup? currentGroup;

  const RecurringEventGroupDialog({
    Key? key,
    this.currentGroup,
  }) : super(key: key);

  @override
  _RecurringEventGroupDialogState createState() => _RecurringEventGroupDialogState();
}

class _RecurringEventGroupDialogState extends State<RecurringEventGroupDialog> {
  final RecurringEventGroupsController _controller = RecurringEventGroupsController.instance;
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  
  Color _selectedColor = Colors.blue;
  bool _isActive = true;
  DateTime? _startDate;
  DateTime? _endDate;
  
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    
    _nameController = TextEditingController(text: widget.currentGroup?.name ?? '');
    _descriptionController = TextEditingController(text: widget.currentGroup?.description ?? '');
    
    if (widget.currentGroup != null) {
      _selectedColor = widget.currentGroup!.color;
      _isActive = widget.currentGroup!.isActive ?? true;
      _startDate = widget.currentGroup!.startDate;
      _endDate = widget.currentGroup!.endDate;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  bool get _isEditing => widget.currentGroup != null;

  void _save() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_startDate != null && _endDate != null && _startDate!.isAfter(_endDate!)) {
      _showErrorDialog('Start date must be before end date');
      return;
    }
    
    RecurringEventGroup group;
    if (_isEditing) {
      group = RecurringEventGroup(
        id: widget.currentGroup!.id,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty 
            ? null 
            : _descriptionController.text.trim(),
        color: _selectedColor,
        isActive: _isActive,
        startDate: _startDate,
        endDate: _endDate,
        recurringEvents: widget.currentGroup!.recurringEvents,
      );
    } else {
      group = RecurringEventGroup(
        id: "-1",
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty 
            ? null 
            : _descriptionController.text.trim(),
        color: _selectedColor,
        isActive: _isActive,
        startDate: _startDate,
        endDate: _endDate,
        recurringEvents: 0,
      );
    }
    _controller.saveGroup(group, !_isEditing)
      .then((v) => {if (mounted) Navigator.pop(context)})
      .catchError((err) async {
        if (mounted)  {
          await Alerts.showErrorDialog(
            context, 
            "Error", 
            "Failed to save the group: $err. Please try again later."
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

  void _showColorPicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Select color"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ColorPicker(
                pickerColor: _selectedColor,
                onColorChanged: (color) {
                  setState(() {
                    _selectedColor = color;
                  });
                },
                colorPickerWidth: 300,
                pickerAreaHeightPercent: 0.8,
                enableAlpha: false, 
                displayThumbColor: true,
                paletteType: PaletteType.hueWheel,
                labelTypes: const [],
                portraitOnly: true,
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Select'),
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
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Name *',
              hintText: 'Enter group name',
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
  return SizedBox(
    width: double.infinity,
    child: RecurrenceInput(eventDate: DateTime.now())
  );
}

  Widget _buildColorPicker() {
    return Row(
      spacing: 8,
      children: [
        const Text('Color: '),
        GestureDetector(
          onTap: _showColorPicker,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _selectedColor,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey),
            ),
          ),
        ),
        Tooltip(
          message: "To visually identify this group's events in the calendar",
          child: Icon(Icons.help_outline, size: 16, color: Colors.grey),
        ),
      ],
    );
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
      title: Text(_isEditing ? 'Edit group' : 'Create a new group'),
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
              _buildColorPicker(),
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