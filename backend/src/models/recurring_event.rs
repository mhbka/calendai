
use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use uuid::Uuid;
use crate::models::{recurring_event_exception::RecurringEventException, recurring_event_group::RecurringEventGroup, rrule::ValidatedRRule};

/// Describes an event which can recur periodically.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct RecurringEvent {
    pub id: Uuid,
    pub group_id: Uuid,
    pub is_active: bool,
    pub title: String,
    pub description: Option<String>,
    pub recurrence_start: DateTime<Utc>,
    pub recurrence_end: Option<DateTime<Utc>>,
    pub start_time: DateTime<Utc>,
    pub end_time: DateTime<Utc>,
    pub rrule: ValidatedRRule
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct NewRecurringEvent {
    pub group_id: Uuid,
    pub title: String,
    pub description: Option<String>,
    pub start_time: DateTime<Utc>,
    pub end_time: Option<DateTime<Utc>>,
    pub rrule: Option<ValidatedRRule>,
}

/// A single instance of a `RecurringEvent`, to be used on the calendar.
/// 
/// *Note to self*: This isn't represented in the database but is constructed in backend.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct RecurringCalendarEvent {
    // details for the event itself
    pub title: String,
    pub description: Option<String>,
    pub start_time: DateTime<Utc>,
    pub end_time: DateTime<Utc>,

    // recurrence metadata
    pub recurring_event_id: Uuid,
    pub group: Option<RecurringEventGroup>,
    pub exception: Option<RecurringEventException>
}

