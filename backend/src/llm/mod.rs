use axum::body::Bytes;
use serde::Serialize;
use crate::models::calendar_event::CalendarEvent;
use crate::models::recurring_event::RecurringEvent;
use crate::models::recurring_event_group::NewRecurringEventGroup;

static GOOGLE_ENDPOINT: &str = "https://generativelanguage.googleapis.com/v1beta/";

#[derive(Serialize)]
pub struct GeneratedEvents {
    events: Vec<CalendarEvent>,
    recurring_events: Vec<RecurringEvent>,
    recurring_event_group: Option<NewRecurringEventGroup>
}


pub struct LLM {

}

impl LLM {
    pub async fn events_from_text(text: String) -> GeneratedEvents {
        todo!()
    }

    pub async fn events_from_audio(blob: Bytes) -> GeneratedEvents {
        todo!()
    }

    pub async fn events_from_image() -> GeneratedEvents {
        todo!()
    }
}