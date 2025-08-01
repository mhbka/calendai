import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:namer_app/utils/recurrence_rrule_conversions.dart';
import 'package:namer_app/widgets/date_picker.dart';
import 'package:rrule/rrule.dart';

enum MonthlyType { byDay, byWeekday }

/// Describes a daily recurrence.
class DailyRecurrence {
  /// How many days between each event.
  int dayPeriodicity = 1;

  DailyRecurrence();
}

/// Describes a weekly recurrence.
class WeeklyRecurrence {
  /// To occur every _ week(s).
  int weekPeriodicity = 1;
  /// Which days of the week the event should occur on (between 0-6).
  Set<int> weekdays = {};

  WeeklyRecurrence();
}

/// Describes a monthly recurrence.
class MonthlyRecurrence {
  /// To occur every _ month(s).
  int monthPeriodicity = 1;
  /// MODE 1: Day of the month the event should occur on (between 1-31; if greater than the month's latest day, defaults to the latest day).
  int mode1DayOfMonth = 1;
  /// MODE 2: Week of the month the event should occur on (between 1-4).
  int mode2WeekOfMonth = 1;
  /// MODE 2: Weekday of the chosen week the event should occur on (between 0-6).
  int mode2Weekday = 0;
  /// Whether to use MODE 1 (simple, day of month 1-31) or MODE 2 (choose week of month + day of that week).
  bool useMode1 = true;
  
  MonthlyRecurrence();
}

/// Describes a yearly recurrence.
class YearlyRecurrence {
  /// Day of the year the event should occur on 
  /// (NOTE: the year is ignored here).
  DateTime _dayOfYear = DateTime.now();

  // `rrule` expects UTC while we represent DateTimes in app as local (this is why Rust is fucking better btw),
  // so we must be careful with any DateTimes members.
  DateTime get dayOfYear => _dayOfYear.toLocal();
  set dayOfYear(DateTime date) => _dayOfYear = date.toUtc();

  YearlyRecurrence();
}

/// Represents a recurrence, or how often and when something should occur.
class RecurrenceData {
  // The chosen type of recurrence
  Frequency type;

  // Input data for each type
  DailyRecurrence dailyRecurrence = DailyRecurrence();
  WeeklyRecurrence weeklyRecurrence = WeeklyRecurrence();
  MonthlyRecurrence monthlyRecurrence = MonthlyRecurrence();
  YearlyRecurrence yearlyRecurrence = YearlyRecurrence();

  // Start/end times and dates
  TimeOfDay startTime;
  TimeOfDay endTime;
  DateTime _startDate;
  DateTime? _endDate;

  // `rrule` expects UTC while we represent DateTimes in app as local (this is why Rust is fucking better btw),
  // so we must be careful with any DateTimes members.
  DateTime get startDate => _startDate.toLocal();
  set startDate(DateTime date) => _startDate = date.toUtc();
  DateTime? get endDate => _endDate?.toLocal();
  set endDate(DateTime? date) => _endDate = date?.toUtc();

  RecurrenceData({
    this.type = Frequency.daily,
    required this.startTime,
    required this.endTime,
    required DateTime startDate,
    DateTime? endDate,
  }) : _startDate = startDate.toUtc(),
       _endDate = endDate?.toUtc();

  /// Gets the next `n` occurrences.
  List<DateTime> getNextOccurrences(int num) {
    var rrule = getRRule();
    return rrule.getInstances(start: _startDate).take(num).toList();
  }

  /// Converts this `RecurrenceData` into a `RecurrenceRule`.
  RecurrenceRule getRRule() {
    return convertToRRule(this);
  }
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
    return RecurrenceData(
      startTime: TimeOfDay.now(),
      endTime: TimeOfDay.now(),
      startDate: DateTime.now()
    );
  }

  @override
  Widget build(BuildContetext) {
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
    return DropdownButtonFormField<Frequency>(
      value: _data.type,
      decoration: const InputDecoration(
        labelText: 'Repeat',
        border: OutlineInputBorder(),
      ),
      items: const [
        DropdownMenuItem(value: Frequency.daily, child: Text('Daily')),
        DropdownMenuItem(value: Frequency.weekly, child: Text('Weekly')),
        DropdownMenuItem(value: Frequency.monthly, child: Text('Monthly')),
        DropdownMenuItem(value: Frequency.yearly, child: Text('Yearly')),
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
      case Frequency.daily:
        chosenOption = _buildDailyOptions();
      case Frequency.weekly:
        chosenOption = _buildWeeklyOptions();
      case Frequency.monthly:
        chosenOption = _buildMonthlyOptions();
      case Frequency.yearly:
        chosenOption = _buildYearlyOptions();
      default:
        // not supporting other Frequencies for now.
        chosenOption = _buildDailyOptions();
      }
    return Row(
      spacing: 8,
      children: [
        Expanded(child: chosenOption),
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
            initialValue: _data.dailyRecurrence.dayPeriodicity.toString(),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            textAlign: TextAlign.center,
            onChanged: (value) => setState(() {
              _data.dailyRecurrence.dayPeriodicity = int.tryParse(value) ?? 1;
            }),
          ),
        ),
        const SizedBox(width: 8),
        Text(_data.dailyRecurrence.dayPeriodicity == 1 ? 'day' : 'days'),
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
                initialValue: _data.weeklyRecurrence.weekPeriodicity.toString(),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                textAlign: TextAlign.center,
                onChanged: (value) => setState(() {
                  _data.weeklyRecurrence.weekPeriodicity = int.tryParse(value) ?? 1;
                }),
              ),
            ),
            const SizedBox(width: 8),
            Text(_data.weeklyRecurrence.weekPeriodicity == 1 ? 'week on:' : 'weeks on:'),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: List.generate(7, (index) {
            final weekday = index + 1;
            final selected = _data.weeklyRecurrence.weekdays.contains(weekday);

            return FilterChip(
              label: Text(_weekdayNames[index]),
              selected: selected,
              onSelected: (isSelected) {
                setState(() {
                  if (isSelected) {
                    _data.weeklyRecurrence.weekdays.add(weekday);
                  } else {
                    _data.weeklyRecurrence.weekdays.remove(weekday);
                    if (_data.weeklyRecurrence.weekdays.isEmpty) {
                      _data.weeklyRecurrence.weekdays.add(widget.eventDate.weekday);
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Period selector
        Row(
          children: [
            const Text('Every'),
            const SizedBox(width: 8),
            SizedBox(
              width: 60,
              child: TextFormField(
                initialValue: _data.monthlyRecurrence.monthPeriodicity.toString(),
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                ),
                onChanged: (value) {
                  final period = int.tryParse(value) ?? 1;
                  if (period >= 1) {
                    _data.monthlyRecurrence.monthPeriodicity = period;
                  }
                },
              ),
            ),
            const SizedBox(width: 8),
            Text(_data.monthlyRecurrence.monthPeriodicity == 1 ? 'month' : 'months'),
          ],
        ),
        const SizedBox(height: 16),
        Column(
          children: [
            // Mode 1: Day of month
            RadioListTile<bool>(
              title: Row(
                children: [
                  const Text('On day'),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 60,
                    child: TextFormField(
                      initialValue: _data.monthlyRecurrence.mode1DayOfMonth.toString(),
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      enabled: _data.monthlyRecurrence.useMode1,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                      ),
                      onChanged: (value) {
                        final day = int.tryParse(value) ?? 1;
                        if (day >= 1 && day <= 31) {
                          _data.monthlyRecurrence.mode1DayOfMonth = day;
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text('of the month'),
                ],
              ),
              value: true,
              groupValue: _data.monthlyRecurrence.useMode1,
              onChanged: (value) => setState(() => _data.monthlyRecurrence.useMode1 = true),
            ),
            // Mode 2: Week + weekday
            RadioListTile<bool>(
              title: Row(
                children: [
                  const Text('On the'),
                  const SizedBox(width: 8),
                  DropdownButton<int>(
                    value: _data.monthlyRecurrence.mode2WeekOfMonth,
                    items: const [
                      DropdownMenuItem(value: 1, child: Text('1st')),
                      DropdownMenuItem(value: 2, child: Text('2nd')),
                      DropdownMenuItem(value: 3, child: Text('3rd')),
                      DropdownMenuItem(value: 4, child: Text('4th')),
                    ],
                    onChanged: _data.monthlyRecurrence.useMode1 ? null : (value) => setState(() => _data.monthlyRecurrence.mode2WeekOfMonth = value ?? 1),
                  ),
                  const SizedBox(width: 8),
                  DropdownButton<int>(
                    value: _data.monthlyRecurrence.mode2Weekday,
                    items: const [
                      DropdownMenuItem(value: 0, child: Text('Monday')),
                      DropdownMenuItem(value: 1, child: Text('Tuesday')),
                      DropdownMenuItem(value: 2, child: Text('Wednesday')),
                      DropdownMenuItem(value: 3, child: Text('Thursday')),
                      DropdownMenuItem(value: 4, child: Text('Friday')),
                    ],
                    onChanged: _data.monthlyRecurrence.useMode1 ? null : (value) => setState(() => _data.monthlyRecurrence.mode2Weekday = value ?? 0),
                  ),
                ],
              ),
              value: false,
              groupValue: _data.monthlyRecurrence.useMode1,
              onChanged: (value) => setState(() => _data.monthlyRecurrence.useMode1 = false),
            ),
          ],
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
          tooltipText: "The default date this group's events start recurring on",
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
          tooltipText: "The default date this group's events stop recurring",
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
    var dates = _data.getNextOccurrences(5);
    return dates.map((date) => DateFormat('dd/MM/yyyy').format(date)).toList().join(', ');
  }
}
