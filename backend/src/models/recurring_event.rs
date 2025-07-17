use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use uuid::Uuid;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct RecurringEvent {
    pub id: Uuid,
    pub group_id: Uuid,
    pub title: String,
    pub event_description: Option<String>,
    pub start_time: DateTime<Utc>,
    pub end_time: Option<DateTime<Utc>>,
    pub rrule: Option<String>, // RFC 5545 recurrence rule format
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct NewRecurringEvent {
    pub group_id: Uuid,
    pub title: String,
    pub event_description: Option<String>,
    pub start_time: DateTime<Utc>,
    pub end_time: Option<DateTime<Utc>>,
    pub rrule: Option<String>,
}