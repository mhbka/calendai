use axum::{debug_handler, extract::{Path, Query, State}, routing::{delete, get, post, put}, Json, Router};
use chrono::{DateTime, Utc};
use serde::Deserialize;
use uuid::Uuid;
use crate::{api::{auth::types::AuthUser, error::ApiResult, AppState}, models::calendar_event::CalendarEvent};

/// The query params for querying events.
#[derive(Deserialize)]
struct EventsQuery {
    start: DateTime<Utc>,
    end: DateTime<Utc> 
}

/// Build the router for calendar event routes.
pub(super) fn router() -> Router<AppState> {
    Router::new()
        .route("/events", post(create_event))
        .route("/events", get(get_events))
        .route("/events/{event_id}", put(update_event))
        .route("/events/{event_id}", delete(delete_event))
}

async fn create_event(
    State(mut app_state): State<AppState>,
    user: AuthUser
) -> ApiResult<()> {
    Ok(())
}

async fn get_events(
    State(mut app_state): State<AppState>,
    Query(params): Query<EventsQuery>,
    user: AuthUser
) -> ApiResult<Json<Vec<CalendarEvent>>> {
    Ok(Json(vec![]))
}

async fn update_event(
    State(mut app_state): State<AppState>,
    Path(event_id): Path<Uuid>,
    user: AuthUser
) -> ApiResult<()> {
    Ok(())
}

async fn delete_event(
    State(mut app_state): State<AppState>,
    Path(event_id): Path<Uuid>,
    user: AuthUser
) -> ApiResult<()> {
    Ok(())
}