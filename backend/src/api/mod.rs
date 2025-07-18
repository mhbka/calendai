use std::sync::Arc;

use axum::Router;
use sqlx::{Pool, Postgres};
use tokio::net::TcpListener;
use crate::config::Config;

pub(super) mod auth;
pub(super) mod error;
mod calendar_events;
mod recurring_event_groups;
mod recurring_events;
mod ai_add_event;

/// State for the app.
#[derive(Clone)]
pub struct AppState {
    pub config: Arc<Config>,
    pub db: Pool<Postgres>
}

/// Run the API.
pub async fn run(config: Config, db: Pool<Postgres>) {
    let app_state = AppState { 
        config: Arc::new(config), 
        db 
    };
    let router = build_app_router(app_state);
    let listener = TcpListener::bind("0.0.0.0:80")
        .await
        .expect("Binding to port should succeed");
    tracing::info!("Running server...");
    axum::serve(listener, router)
        .await
        .expect("The app has been stopped");
}

/// Build the router for the app.
fn build_app_router(state: AppState) -> Router {
    Router::new()
        .nest("/recurring_event_groups", recurring_event_groups::router())
        .nest("/calendar_events", calendar_events::router())
        .nest("/ai_add_event", ai_add_event::router())
        .with_state(state)
}

