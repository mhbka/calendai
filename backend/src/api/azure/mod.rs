use axum::Router;
use crate::api::AppState;

mod calendar;
mod email;
mod token;

pub(super) fn router() -> Router<AppState> {
    Router::new()
        .nest("/calendar", calendar::router())
        .nest("/email", email::router())
        .nest("/token", token::router())
}