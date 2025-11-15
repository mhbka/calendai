use axum::{extract::{Query, State}, routing::get, Json, Router};
use serde::Deserialize;
use crate::{api::{error::ApiResult, AppState}, auth::types::AuthUser, llm::GeneratedEvents, models::{calendar_event::NewCalendarEvent, outlook::{OutlookEmail, OutlookMailMessage}}, services::azure_outlook_service::OutlookListEmailsResponse};

/// A request to generate calendar events from an Outlook email, identified by its ID.
#[derive(Deserialize)]
struct GenerateEventFromEmailRequest {
    mail_id: String,
    timezone_offset_minutes: i32
}

pub(super) fn router() -> Router<AppState> {
    Router::new()
        .route("/fetch_user_emails", get(fetch_user_emails))
        .route("/generate_events_from_email", get(generate_events_from_email))
}

async fn fetch_user_emails(
    State(app_state): State<AppState>,
    user: AuthUser,
) -> ApiResult<Json<Vec<OutlookMailMessage>>> {

    let res = app_state.services.azure
        .fetch_user_emails(user.id, &app_state.config)
        .await?;
    Ok(Json(res.value))
}

async fn generate_events_from_email(
    State(app_state): State<AppState>,
    user: AuthUser,
    Query(request): Query<GenerateEventFromEmailRequest>
) -> ApiResult<Json<GeneratedEvents>> {
    let res = app_state.services.azure
        .generate_events_from_user_email(
            user.id,
            &app_state.config, 
            &request.mail_id, 
            request.timezone_offset_minutes
        )
        .await?;
    Ok(Json(res))
}
