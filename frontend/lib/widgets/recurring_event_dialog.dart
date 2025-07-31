import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:namer_app/models/recurring_event_group.dart';
import 'package:namer_app/widgets/recurrence_input.dart';
import 'package:uuid/uuid.dart';

/// Dialog for creating a new recurring event group/updating a selected group.
class RecurringEventGroupDialog extends StatefulWidget {
  final RecurringEventGroup? currentGroup;
  final Function(RecurringEventGroup, bool) onSave;

  const RecurringEventGroupDialog({
    Key? key,
    this.currentGroup,
    required this.onSave,
  }) : super(key: key);

  @override
  _RecurringEventGroupDialogState createState() => _RecurringEventGroupDialogState();
}

class _RecurringEventGroupDialogState extends State<RecurringEventGroupDialog> {
  // Controllers for form editors
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _recurringEventsController;
  
  // Form state
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
    _recurringEventsController = TextEditingController(text: widget.currentGroup?.recurringEvents.toString() ?? '0');
    
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
    _recurringEventsController.dispose();
    super.dispose();
  }

  bool get _isEditing => widget.currentGroup != null;

  void _save() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validate date range
    if (_startDate != null && _endDate != null && _startDate!.isAfter(_endDate!)) {
      _showErrorDialog('Start date must be before end date');
      return;
    }

    final recurringEvents = num.tryParse(_recurringEventsController.text) ?? 0;
    
    RecurringEventGroup group;
    
    if (_isEditing) {
      // Update existing group
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
        recurringEvents: recurringEvents,
      );
    } else {
      // Create new group
      group = RecurringEventGroup(
        id: const Uuid().v4(),
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty 
            ? null 
            : _descriptionController.text.trim(),
        color: _selectedColor,
        isActive: _isActive,
        startDate: _startDate,
        endDate: _endDate,
        recurringEvents: recurringEvents,
      );
    }

    widget.onSave(group, _isEditing);
    Navigator.pop(context);
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

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate 
          ? (_startDate ?? DateTime.now())
          : (_endDate ?? DateTime.now()),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  void _showColorPicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Color'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Color wheel picker
              ColorPicker(
                pickerColor: _selectedColor,
                onColorChanged: (color) {
                  setState(() {
                    _selectedColor = color;
                  });
                },
                colorPickerWidth: 300,
                pickerAreaHeightPercent: 0.8,
                enableAlpha: false, // Disable alpha since Color doesn't support it in your model
                displayThumbColor: true,
                paletteType: PaletteType.hsvWithHue,
                labelTypes: const [ColorLabelType.rgb, ColorLabelType.hsv],
                portraitOnly: true,
              ),
              const SizedBox(height: 16),
              // Quick color presets
              const Text('Quick Colors:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Colors.red,
                  Colors.pink,
                  Colors.purple,
                  Colors.deepPurple,
                  Colors.indigo,
                  Colors.blue,
                  Colors.lightBlue,
                  Colors.cyan,
                  Colors.teal,
                  Colors.green,
                  Colors.lightGreen,
                  Colors.lime,
                  Colors.yellow,
                  Colors.amber,
                  Colors.orange,
                  Colors.deepOrange,
                  Colors.brown,
                  Colors.grey,
                  Colors.blueGrey,
                ].map((color) => GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedColor = color;
                    });
                  },
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: _selectedColor == color
                          ? Border.all(color: Colors.black, width: 2)
                          : Border.all(color: Colors.grey.shade300),
                    ),
                  ),
                )).toList(),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
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

  Widget _buildRecurringEventsField() {
    return Row(
      children: [
        Expanded(
          child: RecurrenceInput(eventDate: DateTime.now())
        ),
        Tooltip(
          message: 'Describe how often/when this group should occur',
          child: Icon(Icons.help_outline, size: 16, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildColorPicker() {
    return Row(
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
        const SizedBox(width: 8),
        Tooltip(
          message: "Choose a color to visually identify this group's events in the calendar",
          child: Icon(Icons.help_outline, size: 16, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildActiveSwitch() {
    return Row(
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
        const SizedBox(width: 8),
        Tooltip(
          message: 'When inactive, events in this group will be disabled by default',
          child: Icon(Icons.help_outline, size: 16, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime? date,
    required bool isStartDate,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            date != null
                ? '$label: ${date.toLocal().toString().split(' ')[0]}'
                : '$label Date: Not set',
          ),
        ),
        TextButton(
          onPressed: () => _selectDate(context, isStartDate),
          child: Text(date != null ? 'Change' : 'Set'),
        ),
        if (date != null)
          IconButton(
            onPressed: () => setState(() {
              if (isStartDate) {
                _startDate = null;
              } else {
                _endDate = null;
              }
            }),
            icon: const Icon(Icons.clear),
          ),
        Tooltip(
          message: isStartDate
              ? 'Optional start date for when this event group becomes active'
              : 'Optional end date for when this event group expires',
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
              _buildRecurringEventsField(),
              const SizedBox(height: 16),
              _buildColorPicker(),
              const SizedBox(height: 16),
              _buildActiveSwitch(),
              const SizedBox(height: 16),
              _buildDateField(
                label: 'Start',
                date: _startDate,
                isStartDate: true,
              ),
              _buildDateField(
                label: 'End',
                date: _endDate,
                isStartDate: false,
              ),
            ],
          ),
        ),
      ),
      actions: _buildDialogActions(),
    );
  }
}