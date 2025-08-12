use std::io::Cursor;

use axum::{
    extract::{multipart::MultipartError, Multipart, State}, 
    routing::post, 
    Json, Router,
};
use image::ImageReader;
use serde::{Deserialize, Serialize};
use crate::{
    api::{error::{ApiError, ApiResult}, AppState}, auth::types::AuthUser, llm::GeneratedEvents, models::{calendar_event::CalendarEvent, recurring_event::RecurringEvent, recurring_event_group::NewRecurringEventGroup}
};

/// The struct for a text request.
#[derive(Deserialize)]
struct TextToEventRequest {
    text: String,
}

/// Build the router for AI event routes.
pub(super) fn router() -> Router<AppState> {
    Router::new()
        .route("/text", post(process_text_to_events))
        .route("/audio", post(process_audio_to_events))
        .route("/image", post(process_image_to_events))
}

async fn process_text_to_events(
    State(app_state): State<AppState>,
    user: AuthUser,
    Json(request): Json<TextToEventRequest>,
) -> ApiResult<Json<GeneratedEvents>> {
    let events = app_state.services.ai_add_events
        .generate_from_text(request.text)
        .await?;
    Ok(Json(events))
}

async fn process_audio_to_events(
    State(app_state): State<AppState>,
    user: AuthUser,
    mut multipart: Multipart
) -> ApiResult<Json<GeneratedEvents>> {
    if let Some(field) = multipart.next_field().await? {
        // TODO: field + audio validation?
        let data = field.bytes().await?;
        let events = app_state.services.ai_add_events
            .generate_from_audio(data)
            .await?;
        return Ok(Json(events));
    }
    else {
        return Err(
            ApiError::unprocessable_entity(vec![("multipart", "the multipart form had no fields (expected 1)")])
        );
    }
}

async fn process_image_to_events(
    State(app_state): State<AppState>,
    user: AuthUser,
    mut multipart: Multipart
) -> ApiResult<Json<GeneratedEvents>> {
    if let Some(field) = multipart.next_field().await? {
        // TODO: field + audio validation?
        let data = field.bytes().await?;
        let events = app_state.services.ai_add_events
            .generate_from_image(data)
            .await?;
        return Ok(Json(events));
    }
    else {
        return Err(
            ApiError::unprocessable_entity(vec![("multipart", "the multipart form had no fields (expected 1)")])
        );
    }
}