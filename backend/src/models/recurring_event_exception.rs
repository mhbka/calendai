use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use uuid::Uuid;

/// An exception to a recurring event.
/// 
/// For example, if we have a weekly recurring event which will occur on 1 Aug,
/// but we want to move it to 2 Aug,
/// we can use this to represent it.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct RecurringEventException {
    pub id: Uuid,
    pub recurring_event_id: Uuid,
    pub exception_date: DateTime<Utc>,
    pub exception_type: ExceptionType,
    pub modified_event_id: Option<Uuid>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct NewRecurringEventException {
    pub recurring_event_id: Uuid,
    pub exception_date: DateTime<Utc>,
    pub exception_type: ExceptionType,
    pub modified_event_id: Option<Uuid>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "lowercase")]
#[derive(sqlx::Type)]
pub enum ExceptionType {
    Cancelled,
    Modified,
}