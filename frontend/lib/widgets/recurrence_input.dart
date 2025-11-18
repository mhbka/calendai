import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:calendai/utils/recurrence_rrule_conversions.dart';
import 'package:calendai/widgets/date_picker.dart';
import 'package:rrule/rrule.dart';

/// Describes a daily recurrence.
class DailyRecurrence {
  int dayPeriodicity = 1;
  DailyRecurrence();
}

/// Describes a weekly recurrence.
class WeeklyRecurrence {
  int weekPeriodicity = 1;
  Set<int> weekdays = {};
  WeeklyRecurrence();
}

/// Describes a monthly recurrence.
class MonthlyRecurrence {
  int monthPeriodicity = 1;
  int mode1DayOfMonth = 1;
  int mode2WeekOfMonth = 1;
  int mode2Weekday = 0;
  bool useMode1 = true;
  MonthlyRecurrence();
}

/// Describes a yearly recurrence.
class YearlyRecurrence {
  DateTime _dayOfYear = DateTime.now();
  
  DateTime get dayOfYear => _dayOfYear.toLocal();
  set dayOfYear(DateTime date) => _dayOfYear = date.toUtc();
  
  YearlyRecurrence();
}

/// Represents a recurrence pattern.
class RecurrenceData {
  Frequency type;
  DailyRecurrence dailyRecurrence = DailyRecurrence();
  WeeklyRecurrence weeklyRecurrence = WeeklyRecurrence();
  MonthlyRecurrence monthlyRecurrence = MonthlyRecurrence();
  YearlyRecurrence yearlyRecurrence = YearlyRecurrence();
  
  TimeOfDay startTime;
  TimeOfDay endTime;
  DateTime _startDate;
  DateTime? _endDate;

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

  RecurrenceRule rrule() => convertToRRule(this);

  List<DateTime> getNextOccurrences(int num) {
    var rrule = convertToRRule(this);
    return rrule.getInstances(start: _startDate).take(num).toList();
  }

  String describeRecurrence() {
    switch (type) {
      case Frequency.daily:
        if (dailyRecurrence.dayPeriodicity == 1) {
          return "Daily";
        }
        return "Every ${dailyRecurrence.dayPeriodicity} days";
      
      case Frequency.weekly:
        final weekdays = weeklyRecurrence.weekdays;
        final periodicity = weeklyRecurrence.weekPeriodicity;
        
        if (weekdays.isEmpty) {
          return periodicity == 1 ? "Weekly" : "Every $periodicity weeks";
        }
        
        final dayNames = weekdays.map((day) => _getDayName(day)).join(", ");
        if (periodicity == 1) {
          return "Weekly on $dayNames";
        }
        return "Every $periodicity weeks on $dayNames";
      
      case Frequency.monthly:
        final periodicity = monthlyRecurrence.monthPeriodicity;
        final prefix = periodicity == 1 ? "Monthly" : "Every $periodicity months";
        
        if (monthlyRecurrence.useMode1) {
          final day = monthlyRecurrence.mode1DayOfMonth;
          return "$prefix on day $day";
        } else {
          final week = _getWeekName(monthlyRecurrence.mode2WeekOfMonth);
          final dayName = _getDayName(monthlyRecurrence.mode2Weekday);
          return "$prefix on $week $dayName";
        }
      
      case Frequency.yearly:
        final date = yearlyRecurrence.dayOfYear;
        final month = _getMonthName(date.month);
        return "Yearly on $month ${date.day}";

      default:
        return "Unsupported recurrence frequency";
    }
  }

  String _getDayName(int weekday) {
    const days = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"];
    return days[weekday % 7];
  }

  String _getWeekName(int week) {
    const weeks = ["first", "second", "third", "fourth", "last"];
    return weeks[(week - 1).clamp(0, 4)];
  }

  String _getMonthName(int month) {
    const months = ["", "January", "February", "March", "April", "May", "June",
                    "July", "August", "September", "October", "November", "December"];
    return months[month];
  }
}

/// Controller for RecurrenceInput.
class RecurrenceInputController extends ChangeNotifier {
  RecurrenceData _data;

  RecurrenceInputController({RecurrenceData? initialData}) 
    : _data = initialData ?? RecurrenceData(
        startTime: TimeOfDay.now(),
        endTime: TimeOfDay.now(),
        startDate: DateTime.now(),
      );

  RecurrenceData get data => _data;

  void updateData(RecurrenceData newData) {
    _data = newData;
    notifyListeners();
  }

  RecurrenceRule getRRule() => _data.rrule();

  int getEventDurationSeconds() {
    DateTime x = DateTime(2000, 1, 1, _data.startTime.hour, _data.startTime.minute);
    DateTime y = DateTime(2000, 1, 1, _data.endTime.hour, _data.endTime.minute);
    return y.difference(x).inSeconds;
  }
}

/// Widget for configuring recurrence patterns.
class RecurrenceInput extends StatefulWidget {
  final RecurrenceInputController controller;

  const RecurrenceInput({
    super.key,
    required this.controller,
  });

  @override
  State<RecurrenceInput> createState() => _RecurrenceInputState();
}

class _RecurrenceInputState extends State<RecurrenceInput> {
  late RecurrenceData _data;
  final List<String> _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  void initState() {
    super.initState();
    _data = widget.controller._data;
  }

  void _update() {
    widget.controller.updateData(_data);
    setState(() {});
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
          _data.type = value;
          _update();
        }
      },
    );
  }

  Widget _buildFrequencyOptions() {
    switch (_data.type) {
      case Frequency.daily:
        return _buildDailyOptions();
      case Frequency.weekly:
        return _buildWeeklyOptions();
      case Frequency.monthly:
        return _buildMonthlyOptions();
      case Frequency.yearly:
        return _buildYearlyOptions();
      default:
        return _buildDailyOptions();
    }
  }

  Widget _buildDailyOptions() {
    return Row(
      children: [
        const Text('Every'),
        const SizedBox(width: 8),
        SizedBox(
          width: 60,
          child: TextFormField(
            initialValue: _data.dailyRecurrence.dayPeriodicity.toString(),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            textAlign: TextAlign.center,
            onChanged: (value) {
              _data.dailyRecurrence.dayPeriodicity = int.tryParse(value) ?? 1;
              _update();
            },
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
            const Text('Every'),
            const SizedBox(width: 8),
            SizedBox(
              width: 60,
              child: TextFormField(
                initialValue: _data.weeklyRecurrence.weekPeriodicity.toString(),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                textAlign: TextAlign.center,
                onChanged: (value) {
                  _data.weeklyRecurrence.weekPeriodicity = int.tryParse(value) ?? 1;
                  _update();
                },
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
              label: Text(_weekdays[index]),
              selected: selected,
              onSelected: (isSelected) {
                if (isSelected) {
                  _data.weeklyRecurrence.weekdays.add(weekday);
                } else {
                  _data.weeklyRecurrence.weekdays.remove(weekday);
                  if (_data.weeklyRecurrence.weekdays.isEmpty) {
                    _data.weeklyRecurrence.weekdays.add(DateTime.now().weekday);
                  }
                }
                _update();
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
                onChanged: (value) {
                  final period = int.tryParse(value) ?? 1;
                  if (period >= 1) {
                    _data.monthlyRecurrence.monthPeriodicity = period;
                    _update();
                  }
                },
              ),
            ),
            const SizedBox(width: 8),
            Text(_data.monthlyRecurrence.monthPeriodicity == 1 ? 'month' : 'months'),
          ],
        ),
        const SizedBox(height: 16),
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
                  onChanged: (value) {
                    final day = int.tryParse(value) ?? 1;
                    if (day >= 1 && day <= 31) {
                      _data.monthlyRecurrence.mode1DayOfMonth = day;
                      _update();
                    }
                  },
                ),
              ),
              const Text(' of the month'),
            ],
          ),
          value: true,
          groupValue: _data.monthlyRecurrence.useMode1,
          onChanged: (value) {
            _data.monthlyRecurrence.useMode1 = true;
            _update();
          },
        ),
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
                onChanged: _data.monthlyRecurrence.useMode1 ? null : (value) {
                  _data.monthlyRecurrence.mode2WeekOfMonth = value ?? 1;
                  _update();
                },
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
                onChanged: _data.monthlyRecurrence.useMode1 ? null : (value) {
                  _data.monthlyRecurrence.mode2Weekday = value ?? 0;
                  _update();
                },
              ),
            ],
          ),
          value: false,
          groupValue: _data.monthlyRecurrence.useMode1,
          onChanged: (value) {
            _data.monthlyRecurrence.useMode1 = false;
            _update();
          },
        ),
      ],
    );
  }

  Widget _buildYearlyOptions() {
    final now = DateTime.now();
    final monthNames = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];

    return Text('Repeat every year on ${monthNames[now.month - 1]} ${now.day}');
  }

  Widget _buildTimeOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Time'),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _buildTimePicker(_data.startTime, 'Start time', (time) {
              _data.startTime = time;
              _update();
            })),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Text('—'),
            ),
            Expanded(child: _buildTimePicker(_data.endTime, 'End time', (time) {
              _data.endTime = time;
              _update();
            })),
          ],
        ),
      ],
    );
  }

  Widget _buildTimePicker(TimeOfDay time, String label, Function(TimeOfDay) onChanged) {
    return InkWell(
      onTap: () async {
        final picked = await showTimePicker(context: context, initialTime: time);
        if (picked != null) onChanged(picked);
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.access_time, size: 18),
            const SizedBox(width: 8),
            Text(time.format(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildDateOptions() {
    return Column(
      children: [
        DatePicker(
          label: 'Start Date',
          selectedDate: _data.startDate,
          firstDate: DateTime.now(),
          onDateChanged: (date) {
            _data.startDate = date!;
            if (_data.endDate != null && _data.endDate!.isBefore(date)) {
              _data.endDate = null;
            }
            _update();
          },
        ),
        const SizedBox(height: 16),
        DatePicker(
          label: 'End Date',
          selectedDate: _data.endDate,
          firstDate: _data.startDate,
          isNullable: true,
          nullText: 'Repeat forever',
          onDateChanged: (date) {
            _data.endDate = date;
            _update();
          },
        ),
      ],
    );
  }

  Widget _buildPreview() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Next few dates:', style: TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text(_generatePreviewText()),
        ],
      ),
    );
  }

  String _generatePreviewText() {
    try {
      var dates = _data.getNextOccurrences(5);
      return dates.map((date) => DateFormat('dd/MM/yyyy').format(date)).join(', ');
    } catch (e) {
      return 'Invalid recurrence pattern';
    }
  }
}