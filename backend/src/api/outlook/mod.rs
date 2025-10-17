use axum::Router;
use crate::api::AppState;

mod calendar;
mod email;

pub(super) fn router() -> Router<AppState> {
    Router::new()
        .nest("/calendar", calendar::router())
        .nest("/email", email::router())
}