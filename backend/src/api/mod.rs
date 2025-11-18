use std::sync::Arc;
use axum::Router;
use sqlx::PgPool;
use tokio::net::TcpListener;
use tower_http::trace::TraceLayer;
use crate::{config::Config, llm::LLM, services::Services};

pub(super) mod error;
mod calendar_events;
mod recurring_event_groups;
mod recurring_events;
mod ai_add_events;
mod azure;

/// State for the app.
#[derive(Clone)]
pub struct AppState {
    pub config: Arc<Config>,
    pub services: Services,
}

/// Get the router.
pub async fn router(config: Config, services: Services) -> Router {
    let app_state = AppState { 
        config: Arc::new(config), 
        services
    };
    build_app_router(app_state)
}

/// Build the router for the app.
fn build_app_router(state: AppState) -> Router {
    Router::new()
        .nest("/recurring_event_groups", recurring_event_groups::router())
        .nest("/recurring_events", recurring_events::router())
        .nest("/calendar_events", calendar_events::router())
        .nest("/ai_add_event", ai_add_events::router())
        .nest("/azure", azure::router())
        .with_state(state)
        .layer(TraceLayer::new_for_http())
}

