use chrono::NaiveDateTime;
use serde::{Deserialize, Serialize};
use uuid::Uuid;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct RecurringEventGroup {
    pub id: Uuid,
    pub user_id: Uuid,
    pub group_name: String,
    pub group_description: Option<String>,
    pub color: i32,
    pub is_active: Option<bool>,
    pub start_time: Option<NaiveDateTime>,
    pub end_time: Option<NaiveDateTime>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct NewRecurringEventGroup {
    pub user_id: Uuid,
    pub group_name: String,
    pub group_description: Option<String>,
    pub color: i32,
    pub is_active: Option<bool>,
    pub start_time: Option<NaiveDateTime>,
    pub end_time: Option<NaiveDateTime>,
}