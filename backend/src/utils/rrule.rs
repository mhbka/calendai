use chrono::{DateTime, NaiveDate, NaiveDateTime, TimeZone, Utc, offset::LocalResult};
use rrule::{Frequency, NWeekday, RRule, RRuleError, Weekday};
use crate::models::outlook::{
    RecurrencePattern, RecurrencePatternType,
    RecurrenceRange, RecurrenceRangeType,
    DayOfWeek,
};

/// Converts the Outlook calendar event's recurrence pattern to an `RRule`.
pub fn outlook_to_rrule(
    pattern: &RecurrencePattern,
    range: &RecurrenceRange,
    event_start: DateTime<Utc>,
    event_timezone: chrono_tz::Tz
) -> Result<RRule, &'static str> {
    // 1. Determine FREQ
    let freq = match pattern.r#type {
        RecurrencePatternType::Daily => Frequency::Daily,
        RecurrencePatternType::Weekly => Frequency::Weekly,
        RecurrencePatternType::AbsoluteMonthly | RecurrencePatternType::RelativeMonthly => Frequency::Monthly,
        RecurrencePatternType::AbsoluteYearly | RecurrencePatternType::RelativeYearly => Frequency::Yearly,
        RecurrencePatternType::Unknown => {
            return Err("Unknown recurrence pattern");
        }
    };

    let mut rrule = RRule::new(freq);

    // 2. INTERVAL
    if let Some(interval) = pattern.interval {
        if interval > 0 {
            rrule = rrule.interval(interval as u16);
        }
    }

    // 3. BYDAY / BYMONTHDAY / BYMONTH depending on pattern type
    match pattern.r#type {
        RecurrencePatternType::Weekly => {
            if let Some(days) = &pattern.days_of_week {
                let mut conv = Vec::with_capacity(days.len());
                for d in days {
                    conv.push(NWeekday::Every(convert_day(d)));
                }
                rrule = rrule.by_weekday(conv);
            }
        }

        RecurrencePatternType::AbsoluteMonthly => {
            if let Some(dom) = pattern.day_of_month {
                rrule = rrule.by_month_day(vec![dom.try_into().unwrap_or(0)]);
            }
        }

        RecurrencePatternType::RelativeMonthly => {
            // Outlook specifies relative monthly via:
            //   interval + days_of_week + week_index
            //
            // But your reduced model does not include week_index.
            // If needed, add week_index (1..4, -1 for last).
            //
            // For now, treat as weekly-style days (best-effort).
            if let Some(days) = &pattern.days_of_week {
                let conv: Vec<_> = days.iter().map(|d| NWeekday::Every(convert_day(d))).collect();
                rrule = rrule.by_weekday(conv);
            }
        }

        RecurrencePatternType::AbsoluteYearly => {
            if let Some(m) = pattern.month {
                let month = convert_month(m)?;
                rrule = rrule.by_month(&vec![month]);
            }
            if let Some(dom) = pattern.day_of_month {
                rrule = rrule.by_month_day(vec![dom as i8]);
            }
        }

        RecurrencePatternType::RelativeYearly => {
            // Same limitation: Outlook supports positions (first/second/last)
            // Your reduced model does not include pos.
            if let Some(m) = pattern.month {
                let month = convert_month(m)?;
                rrule = rrule.by_month(&vec![month]);
            }
            if let Some(days) = &pattern.days_of_week {
                let conv: Vec<_> = days.iter().map(|d| NWeekday::Every(convert_day(d))).collect();
                rrule = rrule.by_weekday(conv);
            }
        }

        RecurrencePatternType::Daily => {}
        RecurrencePatternType::Unknown => unreachable!(),
    }

    // 4. RANGE: COUNT / UNTIL
    match range.r#type {
        RecurrenceRangeType::NoEnd => {
            // Do nothing: infinite series
        }
        RecurrenceRangeType::EndDate => {
            if let Some(end) = &range.end_date {
                let end_dt = end
                    .and_time(event_start.time());
                let tz = match range.recurrence_time_zone {
                    Some(tz) => tz.into(),
                    None => event_timezone
                };
                let rrule_tz = rrule::Tz::Tz(tz);
                if let LocalResult::Single(dt) = rrule_tz.from_local_datetime(&end_dt) {
                    rrule = rrule.until(dt);
                }
            }
        }
        RecurrenceRangeType::Numbered => {
            if let Some(count) = range.number_of_occurrences {
                if count > 0 {
                    rrule = rrule.count(count as u32);
                }
            }
        }
        RecurrenceRangeType::Unknown => {
            return Err("Unknown recurrence range");
        }
    }

    // 5. Start date (DTSTART)
    let rrule_tz = rrule::Tz::Tz(event_timezone);
    if let LocalResult::Single(dt) = rrule_tz.from_local_datetime(&event_start.naive_local()) {
        let rrule = rrule.validate(dt).map_err(|_| "Failed to validate the RRule")?;
        Ok(rrule)
    }
    else {
        return Err("Failed to convert the start datetime to the event timezone");
    }
}

fn convert_day(d: &DayOfWeek) -> Weekday {
    match d {
        DayOfWeek::Monday => Weekday::Mon,
        DayOfWeek::Tuesday => Weekday::Tue,
        DayOfWeek::Wednesday => Weekday::Wed,
        DayOfWeek::Thursday => Weekday::Thu,
        DayOfWeek::Friday => Weekday::Fri,
        DayOfWeek::Saturday => Weekday::Sat,
        DayOfWeek::Sunday => Weekday::Sun,
        DayOfWeek::Unknown => Weekday::Mon,
    }
}

fn convert_month(m: u8) -> Result<chrono::Month, &'static str> {
    chrono::Month::try_from(m).map_err(|_| "Month is out of range")
}