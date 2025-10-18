use axum::{extract::State, Json, Router};
use serde::Deserialize;
use crate::{api::{error::ApiResult, AppState}, auth::types::AuthUser, llm::GeneratedEvents, models::calendar_event::NewCalendarEvent, services::outlook_service::OutlookListEmailsResponse};

/// A request to fetch a user's emails.
#[derive(Deserialize)]
struct FetchEmailsRequest<'a> {
    access_token: &'a str
}

/// A request to generate calendar events from an Outlook email, identified by its ID.
#[derive(Deserialize)]
struct GenerateEventFromEmailRequest<'a> {
    access_token: &'a str,
    mail_id: &'a str,
    timezone_offset_minutes: i32
}

pub(super) fn router() -> Router<AppState> {
    Router::new()
}

async fn fetch_user_emails(
    State(app_state): State<AppState>,
    user: AuthUser,
    Json(request): Json<FetchEmailsRequest<'_>>
) -> ApiResult<OutlookListEmailsResponse> {
    app_state.services.outlook
        .fetch_user_emails(request.access_token)
        .await
}

async fn generate_events_from_email(
    State(app_state): State<AppState>,
    user: AuthUser,
    Json(request): Json<GenerateEventFromEmailRequest<'_>>
) -> ApiResult<GeneratedEvents> {
    app_state.services.outlook
        .generate_events_from_user_email(
            request.access_token, 
            request.mail_id, 
            request.timezone_offset_minutes
        )
        .await
}
