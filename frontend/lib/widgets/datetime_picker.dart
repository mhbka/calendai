import 'package:flutter/material.dart';

/// A simple start-end datetime picker.
/// 
/// I think this needs to be in another widget, since it uses `ListTile`.
class DateTimePicker extends StatelessWidget {
  DateTime _startTime = DateTime.now();
  DateTime _endTime = DateTime.now().add(Duration(hours: 1));
  final Function(DateTime, DateTime) onDateTimesChanged;

  DateTimePicker({required this.onDateTimesChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          title: Text('Start'),
          subtitle: Text('${_startTime.day}/${_startTime.month}/${_startTime.year} ${_startTime.hour}:${_startTime.minute.toString().padLeft(2, '0')}'),
          trailing: Icon(Icons.edit),
          onTap: () => _selectStartTime(context),
        ),
        ListTile(
          title: Text('End'),
          subtitle: Text('${_endTime.day}/${_endTime.month}/${_endTime.year} ${_endTime.hour}:${_endTime.minute.toString().padLeft(2, '0')}'),
          trailing: Icon(Icons.edit),
          onTap: () => _selectEndTime(context),
        ),
      ],
    );
  }

  Future<void> _selectStartTime(BuildContext context) async {
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
        _startTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
        if (_endTime.isBefore(_startTime)) {
          _endTime = _startTime.add(Duration(hours: 1));
        }
        onDateTimesChanged(_startTime, _endTime);
      }
    }
  }

  Future<void> _selectEndTime(BuildContext context) async {
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
        _endTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
        onDateTimesChanged(_startTime, _endTime);
      }
    }
  }
}