import 'package:flutter/material.dart';
import 'package:calendai/models/recurring_event.dart';
import 'package:calendai/widgets/recurrence_input.dart';
import 'package:rrule/rrule.dart';

/// Converts a `RecurrenceData` to its corresponding `RecurrenceRule`.
/// 
/// Note that some information, especially the start datetime, is lost.
RecurrenceRule convertToRRule(RecurrenceData data) {
  RecurrenceRule rrule;
  switch (data.type) {
    case Frequency.daily:
      rrule = RecurrenceRule(
        frequency: Frequency.daily,
        interval: data.dailyRecurrence.dayPeriodicity,
        until: data.endDate?.toUtc(),
      );
    case Frequency.weekly:
      // Convert weekdays from 0-6 to ByWeekDay format
      final byWeekDays = data.weeklyRecurrence.weekdays
          .map((day) => ByWeekDayEntry(day == 0 ? DateTime.sunday : day))
          .toList();
      rrule = RecurrenceRule(
        frequency: Frequency.weekly,
        interval: data.weeklyRecurrence.weekPeriodicity,
        byWeekDays: byWeekDays,
        until: data.endDate != null ? DateTime(
          data.endDate!.year,
          data.endDate!.month,
          data.endDate!.day,
          23, 59, 59,
        ).toUtc() : null,
      );
    case Frequency.monthly:
      if (data.monthlyRecurrence.useMode1) {
        List<int> monthDays;
        if (data.monthlyRecurrence.mode1DayOfMonth > 31) {
          data.monthlyRecurrence.mode1DayOfMonth = 31;
        }
        // if day > 28, we make sure to fallback for earlier end-of-months
        if (data.monthlyRecurrence.mode1DayOfMonth > 28) {
          monthDays = [
            data.monthlyRecurrence.mode1DayOfMonth,
            -1,
          ];
          if (data.monthlyRecurrence.mode1DayOfMonth == 30) {
            monthDays.add(-2); 
          } else if (data.monthlyRecurrence.mode1DayOfMonth == 29) {
            monthDays.addAll([-2, -3]);
          }
        } else {
          monthDays = [data.monthlyRecurrence.mode1DayOfMonth];
        }
        rrule = RecurrenceRule(
          frequency: Frequency.monthly,
          interval: data.monthlyRecurrence.monthPeriodicity,
          byMonthDays: monthDays,
          until: data.endDate?.toUtc(),
        );
      } else {
        // Mode 2: By week of month + weekday
        final weekday = data.monthlyRecurrence.mode2Weekday == 0 
            ? DateTime.sunday 
            : data.monthlyRecurrence.mode2Weekday;
        rrule = RecurrenceRule(
          frequency: Frequency.monthly,
          interval: data.monthlyRecurrence.monthPeriodicity,
          byWeekDays: [ByWeekDayEntry(weekday, data.monthlyRecurrence.mode2WeekOfMonth)],
          until: data.endDate?.toUtc(),
        );
      }
    case Frequency.yearly:
      final yearlyDate = data.yearlyRecurrence.dayOfYear;
      rrule = RecurrenceRule(
        frequency: Frequency.yearly,
        interval: 1,
        byMonths: [yearlyDate.month],
        byMonthDays: [yearlyDate.day],
        until: data.endDate?.toUtc(),
      );
    default:
      throw ArgumentError('Unsupported frequency type: ${data.type}');
  }
  return rrule;
}

/// Get the `RecurrenceData` described in a `RecurringEvent`.
RecurrenceData getEventRecurrence(RecurringEvent event) {
  return convertToRecurrenceData(
    RecurrenceRule.fromString(event.rrule), 
    event.recurrenceStart, 
    TimeOfDay.fromDateTime(event.recurrenceStart), 
    TimeOfDay.fromDateTime(event.recurrenceStart.add(Duration(seconds: event.eventDurationSeconds)))
  );
}

/// Converts a `RecurrenceRule` to `RecurrenceData`.
/// 
/// Some additional information 
RecurrenceData convertToRecurrenceData(
  RecurrenceRule rrule, 
  DateTime startDate,
  TimeOfDay startTime,
  TimeOfDay endTime
  ) {
  RecurrenceData data = RecurrenceData(
    type: rrule.frequency,
    startTime: startTime, 
    endTime: endTime, 
    startDate: startDate,
    endDate: rrule.until
  );
  switch (rrule.frequency) {
    case Frequency.daily:
      data.dailyRecurrence.dayPeriodicity = rrule.interval ?? 1;
    case Frequency.weekly:
      data.weeklyRecurrence.weekPeriodicity = rrule.interval ?? 1;
      data.weeklyRecurrence.weekdays = rrule.byWeekDays.map((w) => w.day).toSet();
    case Frequency.monthly:
      if (rrule.byMonthDays.isNotEmpty) {
        data.monthlyRecurrence.mode1DayOfMonth = rrule.byMonthDays[0];
      }
      else if (rrule.byWeekDays.isNotEmpty) {
        var weekDayEntry = rrule.byWeekDays[0];
        data.monthlyRecurrence.mode2WeekOfMonth = weekDayEntry.occurrence ?? 1;
        data.monthlyRecurrence.mode2Weekday = weekDayEntry.day;
      }
      else { 
        throw ArgumentError('RecurrenceRule had monthly frequency, but required occurrence fields were empty');
      }
    case Frequency.yearly:
      // note: we only use month and day, so year value doesn't matter here
      data.yearlyRecurrence.dayOfYear = DateTime(0, rrule.byMonths[0], rrule.byMonthDays[0]);
    default:
      throw ArgumentError('Unsupported frequency type: ${data.type}');
  }
    return data;
}


