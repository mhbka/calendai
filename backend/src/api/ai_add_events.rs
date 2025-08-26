use axum::{
    extract::{Multipart, State}, 
    routing::post, 
    Json, Router,
};
use serde::{Deserialize};
use crate::{
    api::{error::{ApiError, ApiResult}, AppState}, auth::types::AuthUser, llm::GeneratedEvents,
};

/// The struct for a text request.
#[derive(Deserialize)]
struct TextToEventRequest {
    text: String,
    timezone_offset_minutes: i32
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
        .generate_from_text(request.text, request.timezone_offset_minutes)
        .await?;
    Ok(Json(events))
}

/// Handler for processing audio into generated events.
/// 
/// The multipart expects 2 fields:
/// - `audio`, containing the binary audio data
/// - `timezone_offset_minutes`, the user's timezone's UTC offset in minutes
async fn process_audio_to_events(
    State(app_state): State<AppState>,
    user: AuthUser,
    mut multipart: Multipart
) -> ApiResult<Json<GeneratedEvents>> {
    if let Some(audio_field) = multipart.next_field().await? {
        let audio_bytes = audio_field.bytes().await?;

        if let Some(offset_field) = multipart.next_field().await? 
        && let Some("timezone_offset_minutes") = offset_field.name()
        && let Ok(timezone_offset_minutes) = offset_field.text().await?.parse::<i32>()
        {
            let events = app_state.services.ai_add_events
                .generate_from_audio(audio_bytes, timezone_offset_minutes)
                .await?;
            return Ok(Json(events));
        }
    }
    return Err(
        ApiError::unprocessable_entity(vec![("multipart", "the multipart form had no fields (expected audio + time offset field)")])
    );
}

/// Handler for processing an image into generated events.
/// 
/// The multipart expects 2 fields:
/// - `image`, containing the binary JPG data
/// - `timezone_offset_minutes`, the user's timezone's UTC offset in minutes
async fn process_image_to_events(
    State(app_state): State<AppState>,
    user: AuthUser,
    mut multipart: Multipart,
) -> ApiResult<Json<GeneratedEvents>> {
    let offset_field = multipart
        .next_field()
        .await?
        .ok_or_else(|| ApiError::unprocessable_entity(vec![("multipart", "Only 1 field found")]))?;
    if offset_field.name() != Some("timezone_offset_minutes") {
        return Err(ApiError::unprocessable_entity(vec![(
            "multipart",
            format!("Second field must be 'timezone_offset_minutes', got: {:?}", offset_field.name()),
        )]));
    }
    let timezone_offset_minutes = offset_field
        .text()
        .await?
        .parse::<i32>()
        .map_err(|_| ApiError::unprocessable_entity(vec![("timezone_offset_minutes", "Unable to parse into i32")]))?;

    let image_field = multipart
        .next_field()
        .await?
        .ok_or(ApiError::unprocessable_entity(vec![("multipart", "No fields found")]))?;
    if image_field.name() != Some("image") {
        return Err(ApiError::unprocessable_entity(vec![(
            "multipart",
            format!("First field must be 'image', got: {:?}", image_field.name()),
        )]));
    }
    let image_bytes = image_field.bytes().await?;

    let events = app_state
        .services
        .ai_add_events
        .generate_from_image(image_bytes, timezone_offset_minutes)
        .await?;
    
    Ok(Json(events))
}