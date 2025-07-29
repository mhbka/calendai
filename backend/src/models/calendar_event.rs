use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use uuid::Uuid;

/// Represents an event on the calendar.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CalendarEvent {
    pub id: Uuid,
    pub user_id: Uuid,
    pub title: String,
    pub description: Option<String>,
    pub location: Option<String>,
    #[serde(alias = "startTime")]
    pub start_time: DateTime<Utc>,
    #[serde(alias = "endTime")]
    pub end_time: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct NewCalendarEvent {
    pub title: String,
    pub description: Option<String>,
    pub location: Option<String>,
    #[serde(alias = "startTime")]
    pub start_time: DateTime<Utc>,
    #[serde(alias = "endTime")]
    pub end_time: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct UpdatedCalendarEvent {
    pub id: Uuid,
    pub title: String,
    pub description: Option<String>,
    pub location: Option<String>,
    #[serde(alias = "startTime")]
    pub start_time: DateTime<Utc>,
    #[serde(alias = "endTime")]
    pub end_time: DateTime<Utc>,
}