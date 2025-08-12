use chrono::{DateTime, Utc};
use schemars::JsonSchema;
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
    pub name: String,
    pub description: Option<String>,
    /// The color to represent the group by (should be `u32`, but we require `i64` for storing in Postgres).
    pub color: i64,
    /// A default `is_active` for all the group's events.
    pub group_is_active: Option<bool>,
    /// A default start date for the group's events.
    pub group_recurrence_start: Option<DateTime<Utc>>,
    /// A default end date for the group's events.
    pub group_recurrence_end: Option<DateTime<Utc>>,
}

#[derive(Debug, Clone, Serialize, Deserialize, JsonSchema)]
pub struct NewRecurringEventGroup {
    pub name: String,
    pub description: Option<String>,
    pub color: i64,
    pub group_is_active: Option<bool>,
    pub group_recurrence_start: Option<DateTime<Utc>>,
    pub group_recurrence_end: Option<DateTime<Utc>>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct UpdatedRecurringEventGroup {
    pub id: Uuid,
    pub name: String,
    pub description: Option<String>,
    pub color: i64,
    pub group_is_active: Option<bool>,
    pub group_recurrence_start: Option<DateTime<Utc>>,
    pub group_recurrence_end: Option<DateTime<Utc>>,
}