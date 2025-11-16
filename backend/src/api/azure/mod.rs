use axum::Router;
use crate::api::AppState;

mod calendar;
mod token;

pub(super) fn router() -> Router<AppState> {
    Router::new()
        .nest("/calendar", calendar::router())
        .nest("/token", token::router())
}