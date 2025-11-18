use axum::{Router, extract::State};
use crate::{api::{AppState, error::ApiResult}, auth::types::AuthUser};
use axum::routing::{post, get};

pub(super) fn router() -> Router<AppState> {
    Router::new()
        .route("/sync", post(sync_with_outlook))
        .route("/ics", get(get_ics_string))
}

async fn sync_with_outlook(
    State(app_state): State<AppState>,
    user: AuthUser,
) -> ApiResult<()> {
    app_state.services.outlook_calendar
        .sync_with_outlook(user.id, &app_state.config)
        .await
}

async fn get_ics_string(
    State(app_state): State<AppState>,
    user: AuthUser,
) -> ApiResult<String> {
    app_state.services.outlook_calendar
        .get_ics_string(user.id)
        .await
}