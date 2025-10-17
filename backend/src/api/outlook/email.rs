use axum::{extract::State, Json, Router};
use crate::{api::{error::ApiResult, AppState}, auth::types::AuthUser, models::calendar_event::NewCalendarEvent};

pub(super) fn router() -> Router<AppState> {
    Router::new()
}

async fn create_events(
    State(app_state): State<AppState>,
    user: AuthUser,
    Json(events): Json<Vec<NewCalendarEvent>>
) -> ApiResult<()> {
    Ok(())
}
