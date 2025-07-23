use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use uuid::Uuid;

/// An exception to a recurring event.
/// 
/// For example, if we have a weekly recurring event which will occur on 1 Aug,
/// but we want to move it to 2 Aug,
/// we can use this to represent it.
/// 
/// **Note**: the `modified` members should only be present if `ExceptionType::Modified`.
/// Otherwise, they will be ignored.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct RecurringEventException {
    pub id: Uuid,
    pub recurring_event_id: Uuid,
    pub exception_date: DateTime<Utc>,
    pub exception_type: ExceptionType,
    pub modified_title: Option<String>,
    pub modified_description: Option<String>,
    pub modified_start_time: Option<DateTime<Utc>>,
    pub modified_end_time: Option<DateTime<Utc>>
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct NewRecurringEventException {
    pub recurring_event_id: Uuid,
    pub exception_date: DateTime<Utc>,
    pub exception_type: ExceptionType,
    pub modified_title: Option<String>,
    pub modified_description: Option<String>,
    pub modified_start_time: Option<DateTime<Utc>>,
    pub modified_end_time: Option<DateTime<Utc>>
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
#[serde(rename_all = "lowercase")]
#[derive(sqlx::Type)]
#[sqlx(type_name = "varchar", rename_all = "lowercase")]
pub enum ExceptionType {
    Cancelled,
    Modified,
}