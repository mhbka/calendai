use axum::Router;
use crate::api::AppState;

pub(super) fn router() -> Router<AppState> {
    Router::new()
}