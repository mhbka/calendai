import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:namer_app/widgets/date_picker.dart';

enum RecurrenceType { daily, weekly, monthly, yearly }
enum MonthlyType { byDay, byWeekday }

/// Represents a recurrence, or how often and when something should occur.
class RecurrenceData {
  RecurrenceType type;
  int interval;
  Set<int> weekdays;
  MonthlyType monthlyType;
  int monthDay;
  int weekdayOccurrence;
  int weekday;
  TimeOfDay startTime;
  TimeOfDay endTime;
  DateTime startDate;
  DateTime? endDate;

  RecurrenceData({
    this.type = RecurrenceType.daily,
    this.interval = 1,
    Set<int>? weekdays,
    this.monthlyType = MonthlyType.byDay,
    this.monthDay = 1,
    this.weekdayOccurrence = 1,
    this.weekday = 1,
    required this.startTime,
    required this.endTime,
    required this.startDate,
    this.endDate,
  }) : weekdays = weekdays ?? {};
}

/// A widget for describing something's recurrence.
class RecurrenceInput extends StatefulWidget {
  final DateTime eventDate;
  final RecurrenceData? initialData;

  const RecurrenceInput({
    Key? key,
    required this.eventDate,
    this.initialData,
  }) : super(key: key);

  @override
  State<RecurrenceInput> createState() => _RecurrenceInputState();
}

class _RecurrenceInputState extends State<RecurrenceInput> {
  late RecurrenceData _data;
  final List<String> _weekdayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  void initState() {
    super.initState();
    _data = widget.initialData ?? _getDefaultData();
  }

  RecurrenceData _getDefaultData() {
    final weekday = widget.eventDate.weekday;
    final day = widget.eventDate.day;
    final weekdayOccurrence = ((day - 1) ~/ 7) + 1;

    return RecurrenceData(
      weekdays: {weekday},
      monthDay: day,
      weekday: weekday,
      weekdayOccurrence: weekdayOccurrence,
      startTime: TimeOfDay.now(),
      endTime: TimeOfDay.now(),
      startDate: DateTime.now()
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFrequencySelector(),
        const SizedBox(height: 16),
        _buildFrequencyOptions(),
        const SizedBox(height: 16),
        _buildTimeOptions(),
        const SizedBox(height: 16),
        _buildDateOptions(),
        const SizedBox(height: 16),
        _buildPreview(),
      ],
    );
  }

  Widget _buildFrequencySelector() {
    return DropdownButtonFormField<RecurrenceType>(
      value: _data.type,
      decoration: const InputDecoration(
        labelText: 'Repeat',
        border: OutlineInputBorder(),
      ),
      items: const [
        DropdownMenuItem(value: RecurrenceType.daily, child: Text('Daily')),
        DropdownMenuItem(value: RecurrenceType.weekly, child: Text('Weekly')),
        DropdownMenuItem(value: RecurrenceType.monthly, child: Text('Monthly')),
        DropdownMenuItem(value: RecurrenceType.yearly, child: Text('Yearly')),
      ],
      onChanged: (value) {
        if (value != null) {
          setState(() => _data.type = value);
        }
      },
    );
  }

  Widget _buildFrequencyOptions() {
    Widget chosenOption;
    switch (_data.type) {
      case RecurrenceType.daily:
        chosenOption = _buildDailyOptions();
      case RecurrenceType.weekly:
        chosenOption = _buildWeeklyOptions();
      case RecurrenceType.monthly:
        chosenOption = _buildMonthlyOptions();
      case RecurrenceType.yearly:
        chosenOption = _buildYearlyOptions();
      }
    return Row(
      spacing: 8,
      children: [
        chosenOption,
        Tooltip(
          message: "The default periodicity for the group's events",
          child: Icon(Icons.help_outline, size: 16, color: Colors.grey),
        )
      ],
    );
  }

  Widget _buildDailyOptions() {
    return Row(
      children: [
        const Text('Repeat every'),
        const SizedBox(width: 8),
        SizedBox(
          width: 60,
          child: TextFormField(
            initialValue: _data.interval.toString(),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            textAlign: TextAlign.center,
            onChanged: (value) => setState(() {
              _data.interval = int.tryParse(value) ?? 1;
            }),
          ),
        ),
        const SizedBox(width: 8),
        Text(_data.interval == 1 ? 'day' : 'days'),
      ],
    );
  }

  Widget _buildWeeklyOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('Repeat every'),
            const SizedBox(width: 8),
            SizedBox(
              width: 60,
              child: TextFormField(
                initialValue: _data.interval.toString(),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                textAlign: TextAlign.center,
                onChanged: (value) => setState(() {
                  _data.interval = int.tryParse(value) ?? 1;
                }),
              ),
            ),
            const SizedBox(width: 8),
            Text(_data.interval == 1 ? 'week on:' : 'weeks on:'),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: List.generate(7, (index) {
            final weekday = index + 1;
            final selected = _data.weekdays.contains(weekday);

            return FilterChip(
              label: Text(_weekdayNames[index]),
              selected: selected,
              onSelected: (isSelected) {
                setState(() {
                  if (isSelected) {
                    _data.weekdays.add(weekday);
                  } else {
                    _data.weekdays.remove(weekday);
                    if (_data.weekdays.isEmpty) {
                      _data.weekdays.add(widget.eventDate.weekday);
                    }
                  }
                });
              },
            );
          }),
        ),
      ],
    );
  }

  Widget _buildMonthlyOptions() {
    return Column(
      children: [
        RadioListTile<MonthlyType>(
          title: Text('On day ${_data.monthDay} of the month'),
          value: MonthlyType.byDay,
          groupValue: _data.monthlyType,
          onChanged: (value) => setState(() {
            _data.monthlyType = value!;
          }),
        ),
        RadioListTile<MonthlyType>(
          title: Text('On the ${_getOrdinal(_data.weekdayOccurrence)} ${_weekdayNames[_data.weekday - 1]} of the month'),
          value: MonthlyType.byWeekday,
          groupValue: _data.monthlyType,
          onChanged: (value) => setState(() {
            _data.monthlyType = value!;
          }),
        ),
      ],
    );
  }

  Widget _buildYearlyOptions() {
    final monthName = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ][widget.eventDate.month - 1];

    return Text(
      'Repeat every year on $monthName ${widget.eventDate.day}',
      style: Theme.of(context).textTheme.bodyMedium,
    );
  }

  Widget _buildTimeOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          spacing: 8,
          children: [
            Text(
              'Time',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            Tooltip(
              message: "The default start and end time for this group's events",
              child: Icon(Icons.help_outline, size: 16, color: Colors.grey),
            )
          ],
        ),
        SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () async {
                  final TimeOfDay? pickedTime = await showTimePicker(
                    context: context,
                    initialTime: _data.startTime,
                  );
                  
                  if (pickedTime != null) {
                    setState(() {
                      _data.startTime = pickedTime;
                    });
                  }
                },
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.access_time, size: 18, color: Colors.grey.shade600),
                      SizedBox(width: 8),
                      Text(
                        _data.startTime?.format(context) ?? 'Start time',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Text('—', style: TextStyle(color: Colors.grey.shade600)),
            ),
            Expanded(
              child: InkWell(
                onTap: () async {
                  final TimeOfDay? pickedTime = await showTimePicker(
                    context: context,
                    initialTime: _data.endTime,
                  );
                  
                  if (pickedTime != null) {
                    setState(() {
                      _data.endTime = pickedTime;
                    });
                  }
                },
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.access_time, size: 18, color: Colors.grey.shade600),
                      SizedBox(width: 8),
                      Text(
                        _data.endTime.format(context),
                        style: TextStyle(
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  } 

  Widget _buildDateOptions() {
    return Column(
      children: [
        DatePicker(
          label: 'Start Date',
          selectedDate: _data.startDate,
          firstDate: DateTime.now(),
          accentColor: Colors.blue,
          onDateChanged: (date) {
            setState(() {
              _data.startDate = date!; // Non-nullable, so safe to use !
              // Reset end date if it's before the new start date
              if (_data.endDate != null && _data.endDate!.isBefore(date)) {
                _data.endDate = null;
              }
            });
          },
        ),
        const SizedBox(height: 16),
        DatePicker(
          label: 'End Date',
          selectedDate: _data.endDate,
          firstDate: _data.startDate,
          isNullable: true,
          nullText: 'Repeat forever',
          accentColor: Colors.green,
          onDateChanged: (date) {
            setState(() {
              _data.endDate = date;
            });
          },
        ),
      ],
    );
  }

  Widget _buildPreview() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Next few dates:', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 4),
          Text(_generatePreviewText(), style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
  
  String _generatePreviewText() {
    final dates = <String>[];
    var current = widget.eventDate;

    while (dates.length < 4) {
      if (_data.endDate != null && current.isAfter(_data.endDate!)) {
        break;
      }

      dates.add('${current.day}/${current.month}/${current.year}');

      switch (_data.type) {
        case RecurrenceType.daily:
          current = current.add(Duration(days: _data.interval));
        case RecurrenceType.weekly:
          current = current.add(Duration(days: 7 * _data.interval));
        case RecurrenceType.monthly:
          current = DateTime(current.year, current.month + _data.interval, current.day);
        case RecurrenceType.yearly:
          current = DateTime(current.year + 1, current.month, current.day);
      }
    }

    return dates.join(', ');
  }

  String _getOrdinal(int number) {
    if (number >= 11 && number <= 13) return '${number}th';
    switch (number % 10) {
      case 1: return '${number}st';
      case 2: return '${number}nd';
      case 3: return '${number}rd';
      default: return '${number}th';
    }
  }
}
