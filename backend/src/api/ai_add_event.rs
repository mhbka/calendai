use axum::{
    extract::State, 
    routing::post, 
    Json, Router,
};
use serde::{Deserialize, Serialize};
use crate::{
    api::{auth::types::AuthUser, error::ApiResult, AppState}, 
    models::{calendar_event::CalendarEvent, recurring_event::RecurringEvent}
};

/// The struct for a text request.
#[derive(Deserialize)]
struct TextToEventRequest {
    text: String,
}

/// The response for an AI event request.
#[derive(Serialize)]
struct AIEventResponse {
    events: Vec<CalendarEvent>,
    recurring_events: Vec<RecurringEvent>
}

/// Build the router for AI event routes.
pub(super) fn router() -> Router<AppState> {
    Router::new()
        .route("/text", post(process_text_to_event))
        .route("/audio", post(process_audio_to_event))
}

async fn process_text_to_event(
    State(app_state): State<AppState>,
    user: AuthUser,
    Json(payload): Json<TextToEventRequest>,
) -> ApiResult<Json<AIEventResponse>> {
    // Implementation:
    // 1. Validate input text
    // 2. Call AI service to process text
    // 3. Parse AI response into CalendarEvent
    // 4. Save event to database
    // 5. Return created events

    let response = AIEventResponse {
        events: vec![],
        recurring_events: vec![]
    };
    Ok(Json(response))
}

async fn process_audio_to_event(
    State(app_state): State<AppState>,
    user: AuthUser,
    // ContentLengthLimit(audio_data): ContentLengthLimit<Bytes, { 10 * 1024 * 1024 }>, // 10MB limit
) -> ApiResult<Json<AIEventResponse>> {
    // Implementation:
    // 1. Validate audio data format/size
    // 2. Call speech-to-text service
    // 3. Call AI service to process transcribed text
    // 4. Parse AI response into CalendarEvent
    // 5. Save event to database
    // 6. Return created events

    let response = AIEventResponse {
        events: vec![],
        recurring_events: vec![]
    };
    Ok(Json(response))
}