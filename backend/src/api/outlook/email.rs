use axum::{extract::{Query, State}, routing::get, Json, Router};
use serde::Deserialize;
use crate::{api::{error::ApiResult, AppState}, auth::types::AuthUser, llm::GeneratedEvents, models::{calendar_event::NewCalendarEvent, outlook::{OutlookEmail, OutlookMailMessage}}, services::outlook_service::OutlookListEmailsResponse};

/// A request to fetch a user's emails.
#[derive(Deserialize)]
struct FetchEmailsRequest {
    access_token: String
}

/// A request to generate calendar events from an Outlook email, identified by its ID.
#[derive(Deserialize)]
struct GenerateEventFromEmailRequest {
    access_token: String,
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
    Query(request): Query<FetchEmailsRequest>
) -> ApiResult<Json<Vec<OutlookMailMessage>>> {
    let res = app_state.services.outlook
        .fetch_user_emails(&request.access_token)
        .await?;
    Ok(Json(res.value))
}

async fn generate_events_from_email(
    State(app_state): State<AppState>,
    user: AuthUser,
    Query(request): Query<GenerateEventFromEmailRequest>
) -> ApiResult<Json<GeneratedEvents>> {
    let res = app_state.services.outlook
        .generate_events_from_user_email(
            &request.access_token, 
            &request.mail_id, 
            request.timezone_offset_minutes
        )
        .await?;
    Ok(Json(res))
}
