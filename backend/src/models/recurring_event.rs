
use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use uuid::Uuid;
use crate::models::{recurring_event_group::RecurringEventGroup, rrule::ValidatedRRule, time::Second};

/// A single instance of a `RecurringEvent`, to be used on the calendar.
/// 
/// *NOTE*: This isn't represented in the database but is constructed in the backend.
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct RecurringCalendarEvent {
    // event metadata
    pub title: String,
    pub description: Option<String>,
    pub location: Option<String>,
    pub start_time: DateTime<Utc>,
    pub end_time: DateTime<Utc>,

    // recurrence metadata
    pub recurring_event_id: Uuid,
    pub exception_id: Option<Uuid>,
    pub group: Option<RecurringEventGroup>,
}

/// Describes an event which can recur periodically.
/// 
/// **NOTE**: `rrule` already contains the start/end dates for the recurrence.
/// `recurrence_start`/`recurrence_end` is used for querying for recurring events between a given start/end datetime in the database.
/// 
/// Thus, it is critical that they both contain the same datetime. 
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct RecurringEvent {
    pub id: Uuid,
    pub group_id: Option<Uuid>,
    pub user_id: Uuid,
    pub is_active: bool,
    pub title: String,
    pub description: Option<String>,
    pub location: Option<String>,
    pub event_duration_seconds: Second,
    pub recurrence_start: DateTime<Utc>,
    pub recurrence_end: Option<DateTime<Utc>>,
    pub rrule: ValidatedRRule
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct NewRecurringEvent {
    pub group_id: Option<Uuid>,
    pub is_active: bool,
    pub title: String,
    pub description: Option<String>,
    pub location: Option<String>,
    pub event_duration_seconds: Second,
    pub recurrence_start: DateTime<Utc>,
    pub recurrence_end: Option<DateTime<Utc>>,
    pub rrule: ValidatedRRule
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct UpdatedRecurringEvent {
    pub id: Uuid,
    pub group_id: Option<Uuid>,
    pub is_active: bool,
    pub title: String,
    pub description: Option<String>,
    pub location: Option<String>,
    pub event_duration_seconds: Second,
    pub recurrence_start: DateTime<Utc>,
    pub recurrence_end: Option<DateTime<Utc>>,
    pub rrule: ValidatedRRule
}





