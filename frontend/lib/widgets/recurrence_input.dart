import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum RecurrenceType { none, daily, weekly, monthly, yearly }
enum MonthlyType { byDay, byWeekday }

class RecurrenceData {
  RecurrenceType type;
  int interval;
  Set<int> weekdays;
  MonthlyType monthlyType;
  int monthDay;
  int weekdayOccurrence;
  int weekday;
  DateTime? endDate;
  bool hasEndDate;

  RecurrenceData({
    this.type = RecurrenceType.none,
    this.interval = 1,
    Set<int>? weekdays,
    this.monthlyType = MonthlyType.byDay,
    this.monthDay = 1,
    this.weekdayOccurrence = 1,
    this.weekday = 1,
    this.endDate,
    this.hasEndDate = false,
  }) : weekdays = weekdays ?? {};
}

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
        _buildEndDateOptions(),
        if (_data.type != RecurrenceType.none) ...[
          const SizedBox(height: 16),
          _buildPreview(),
        ],
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
        DropdownMenuItem(value: RecurrenceType.none, child: Text('Does not repeat')),
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
    switch (_data.type) {
      case RecurrenceType.daily:
        return _buildDailyOptions();
      case RecurrenceType.weekly:
        return _buildWeeklyOptions();
      case RecurrenceType.monthly:
        return _buildMonthlyOptions();
      case RecurrenceType.yearly:
        return _buildYearlyOptions();
      case RecurrenceType.none:
      default:
        return const SizedBox.shrink();
    }
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

  Widget _buildEndDateOptions() {
    if (_data.type == RecurrenceType.none) return const SizedBox.shrink();

    return Column(
      children: [
        RadioListTile<bool>(
          title: const Text('Repeat forever'),
          value: false,
          groupValue: _data.hasEndDate,
          onChanged: (_) => setState(() {
            _data.hasEndDate = false;
            _data.endDate = null;
          }),
        ),
        RadioListTile<bool>(
          title: Row(
            children: [
              const Text('End on '),
              TextButton(
                onPressed: _data.hasEndDate ? _selectEndDate : null,
                child: Text(
                  _data.endDate != null
                      ? '${_data.endDate!.day}/${_data.endDate!.month}/${_data.endDate!.year}'
                      : 'Select date',
                ),
              ),
            ],
          ),
          value: true,
          groupValue: _data.hasEndDate,
          onChanged: (_) => setState(() {
            _data.hasEndDate = true;
            if (_data.endDate == null) _selectEndDate();
          }),
        ),
      ],
    );
  }

  Future<void> _selectEndDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _data.endDate ?? widget.eventDate.add(const Duration(days: 30)),
      firstDate: widget.eventDate,
      lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
    );

    if (selected != null) {
      setState(() {
        _data.endDate = selected;
        _data.hasEndDate = true;
      });
    }
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
      if (_data.hasEndDate && _data.endDate != null && current.isAfter(_data.endDate!)) {
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
        case RecurrenceType.none:
          return dates.first;
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
