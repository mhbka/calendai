import 'package:flutter/material.dart';

/// A simple start-end datetime picker.
/// 
/// I think this needs to be in another widget, since it uses `ListTile`.
class DateTimePicker extends StatelessWidget {
  DateTime startTime;
  DateTime endTime;
  final Function(DateTime, DateTime) onDateTimesChanged;

  DateTimePicker({
    required this.startTime,
    required this.endTime,
    required this.onDateTimesChanged
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          title: Text('Start'),
          subtitle: Text('${startTime.day}/${startTime.month}/${startTime.year} ${startTime.hour}:${startTime.minute.toString().padLeft(2, '0')}'),
          trailing: Icon(Icons.edit),
          onTap: () => _selectStartTime(context),
        ),
        ListTile(
          title: Text('End'),
          subtitle: Text('${endTime.day}/${endTime.month}/${endTime.year} ${endTime.hour}:${endTime.minute.toString().padLeft(2, '0')}'),
          trailing: Icon(Icons.edit),
          onTap: () => _selectEndTime(context),
        ),
      ],
    );
  }

  Future<void> _selectStartTime(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: startTime,
      firstDate: DateTime.now().subtract(Duration(days: 365)),
      lastDate: DateTime.now().add(Duration(days: 365)),
    );
    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(startTime),
      );
      if (time != null) {
        startTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
        if (endTime.isBefore(startTime)) {
          endTime = startTime.add(Duration(hours: 1));
        }
        onDateTimesChanged(startTime, endTime);
      }
    }
  }

  Future<void> _selectEndTime(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: endTime,
      firstDate: startTime,
      lastDate: DateTime.now().add(Duration(days: 365)),
    );
    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(endTime),
      );
      if (time != null) {
        endTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
        onDateTimesChanged(startTime, endTime);
      }
    }
  }
}