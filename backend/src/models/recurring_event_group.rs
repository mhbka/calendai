use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use uuid::Uuid;

/// A group of `RecurringEvent`s.
/// 
/// Default values can be set for all of a group's events' `is_active` and `group_recurrence_start/end` values.
/// Do note that these can still be overridden on the event level.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct RecurringEventGroup {
    pub id: Uuid,
    pub user_id: Uuid,
    pub group_name: String,
    pub description: Option<String>,
    /// The color to represent the group by.
    pub color: i32,
    /// A default `is_active` for all the group's events.
    pub group_is_active: Option<bool>,
    /// A default `group_recurrence_start` for all the group's events.
    pub group_recurrence_start: Option<DateTime<Utc>>,
    /// A default `group_recurrence_end` for all the group's events.
    pub group_recurrence_end: Option<DateTime<Utc>>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct NewRecurringEventGroup {
    pub user_id: Uuid,
    pub group_name: String,
    pub description: Option<String>,
    pub color: i32,
    pub group_is_active: Option<bool>,
    pub group_recurrence_start: Option<DateTime<Utc>>,
    pub group_recurrence_end: Option<DateTime<Utc>>,
}