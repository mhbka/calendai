use axum::{Json, Router, extract::{Query, State}, routing::{get, post}};
use serde::Deserialize;
use crate::{api::{error::ApiResult, AppState}, auth::types::AuthUser, llm::GeneratedEvents, models::{calendar_event::NewCalendarEvent, outlook::{OutlookEmail, OutlookMailMessage}}, services::azure_token_service::OutlookListEmailsResponse};

pub(super) fn router() -> Router<AppState> {
    Router::new()   
        .route("/", post(insert_refresh_token))
        .route("/", get(verify_user_token))
}

async fn insert_refresh_token(
    State(app_state): State<AppState>,
    user: AuthUser,
) -> ApiResult<()> {
    app_state.services.azure_token
        .store_user_tokens(user.id, user.azure_refresh_token, &app_state.config)
        .await?;
    Ok(())
}

async fn verify_user_token(
    State(app_state): State<AppState>,
    user: AuthUser,
) -> ApiResult<()> {
    let _ = app_state.services.azure_token
        .get_valid_access_token(user.id, &app_state.config)
        .await?;
    Ok(())
}