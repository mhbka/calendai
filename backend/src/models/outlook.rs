//! API reference: https://learn.microsoft.com/en-us/graph/api/overview?view=graph-rest-1.0
//! 
//! Types only contain fields we actually need/use.

use std::str::FromStr;

use chrono::{DateTime, NaiveDate, NaiveDateTime, Utc};
use chrono_tz::Tz;
use serde::Deserialize;
use windows_timezones::WindowsTimezone;

#[derive(Debug, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct OutlookCalendarResponse {
    #[serde(rename = "@odata.nextLink")]
    pub next_link: Option<String>,
    #[serde(rename = "@odata.deltaLink")]
    pub delta_link: Option<String>,
    pub value: Vec<OutlookDeltaEvent>
}

#[derive(Debug, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct OutlookSyncState {
    pub delta_link: String,
    pub last_sync: DateTime<Utc>
}

#[derive(Debug, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct OutlookCalendar {
    pub id: String,
    pub name: String
}

#[derive(Debug, Deserialize)]
#[serde(rename_all = "camelCase")]
#[serde(untagged)]
pub enum OutlookDeltaEvent {
    Deleted {
        id: String,
        #[serde(rename = "@removed")]
        removed: RemovedInfo,
    },
    Event(OutlookCalendarEvent),
}

#[derive(Debug, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct RemovedInfo {
    pub reason: String,
}

#[derive(Debug, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct OutlookCalendarEvent {
    pub id: String,
    pub subject: Option<String>,
    //pub body: Option<ItemBody>,
    pub body_preview: Option<String>,
    pub location: Option<OutlookLocation>,
    pub start: OutlookDateTimeTimeZone,
    pub end: OutlookDateTimeTimeZone,
    //pub recurrence: Option<OutlookRecurrence>,
    //pub series_master_id: Option<String>,
    //pub r#type: OutlookEventType,
}

#[derive(Debug, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct ItemBody {
    pub content_type: String, // "text" or "html"
    pub content: String,
}

#[derive(Debug, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct OutlookLocation {
    pub display_name: Option<String>,
}

#[derive(Debug, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct OutlookDateTimeTimeZone {
    #[serde(deserialize_with = "crate::utils::datetime::deserialize_naive_dt")]
    pub date_time: NaiveDateTime, 
    #[serde(deserialize_with = "crate::utils::datetime::deserialize_windows_tz")]
    pub time_zone: WindowsTimezone, 
}

impl OutlookDateTimeTimeZone {
    /// Converts the datetime to Utc.
    pub fn to_utc(&self) -> DateTime<Utc> {
        self.date_time
            .and_local_timezone::<Tz>(self.time_zone.into())
            .single()
            .unwrap()
            .to_utc()
    }
}

#[derive(Debug, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct OutlookRecurrence {
    pub pattern: RecurrencePattern,
    pub range: RecurrenceRange,
}

#[derive(Debug, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct RecurrencePattern {
    pub r#type: RecurrencePatternType, 
    pub interval: Option<i32>,
    pub days_of_week: Option<Vec<DayOfWeek>>,
    pub day_of_month: Option<u8>,
    pub month: Option<u8>,
}

#[derive(Debug, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct RecurrenceRange {
    pub r#type: RecurrenceRangeType,
    pub start_date: NaiveDate,    
    pub end_date: Option<NaiveDate>,
    pub recurrence_time_zone: Option<WindowsTimezone>,
    pub number_of_occurrences: Option<i32>,
}

#[derive(Debug, Deserialize)]
#[serde(rename_all = "camelCase")]
pub enum OutlookEventType {
    #[serde(rename = "singleInstance")]
    SingleInstance,
    #[serde(rename = "occurrence")]
    Occurrence,
    #[serde(rename = "exception")]
    Exception,
    #[serde(rename = "seriesMaster")]
    SeriesMaster,
    #[serde(other)]
    Unknown,
}

#[derive(Debug, Deserialize)]
#[serde(rename_all = "camelCase")]
pub enum RecurrencePatternType {
    #[serde(rename = "daily")]
    Daily,
    #[serde(rename = "weekly")]
    Weekly,
    #[serde(rename = "absoluteMonthly")]
    AbsoluteMonthly,
    #[serde(rename = "relativeMonthly")]
    RelativeMonthly,
    #[serde(rename = "absoluteYearly")]
    AbsoluteYearly,
    #[serde(rename = "relativeYearly")]
    RelativeYearly,
    #[serde(other)]
    Unknown,
}

#[derive(Debug, Deserialize)]
#[serde(rename_all = "camelCase")]
pub enum RecurrenceRangeType {
    #[serde(rename = "noEnd")]
    NoEnd,
    #[serde(rename = "endDate")]
    EndDate,
    #[serde(rename = "numbered")]
    Numbered,
    #[serde(other)]
    Unknown,
}

#[derive(Debug, Deserialize)]
#[serde(rename_all = "camelCase")]
pub enum DayOfWeek {
    #[serde(rename = "monday")]
    Monday,
    #[serde(rename = "tuesday")]
    Tuesday,
    #[serde(rename = "wednesday")]
    Wednesday,
    #[serde(rename = "thursday")]
    Thursday,
    #[serde(rename = "friday")]
    Friday,
    #[serde(rename = "saturday")]
    Saturday,
    #[serde(rename = "sunday")]
    Sunday,
    #[serde(other)]
    Unknown,
}