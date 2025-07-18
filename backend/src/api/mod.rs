use std::sync::Arc;

use axum::Router;
use sqlx::{Pool, Postgres};
use crate::config::Config;

pub(super) mod auth;
pub(super) mod error;
mod calendar_events;
mod recurring_event_groups;
mod recurring_events;

/// State for the app.
#[derive(Clone)]
struct AppState {
    config: Arc<Config>,
    db: Pool<Postgres>
}

/// Build the router for the app.
fn router() -> Router<AppState> {
    Router::new()
}

