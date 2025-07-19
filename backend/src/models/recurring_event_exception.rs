use chrono::NaiveDateTime;
use serde::{Deserialize, Serialize};
use uuid::Uuid;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct RecurringEventException {
    pub id: Uuid,
    pub recurring_event_id: Uuid,
    pub exception_date: NaiveDateTime,
    pub exception_type: ExceptionType,
    pub modified_event_id: Option<Uuid>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct NewRecurringEventException {
    pub recurring_event_id: Uuid,
    pub exception_date: NaiveDateTime,
    pub exception_type: ExceptionType,
    pub modified_event_id: Option<Uuid>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum ExceptionType {
    Cancelled,
    Modified,
}