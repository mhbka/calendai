use axum::{extract::{Path, Query, State}, routing::{delete, get, post, put}, Json, Router};
use chrono::{DateTime, Utc};
use serde::Deserialize;
use uuid::Uuid;
use crate::{
    api::{error::ApiResult, AppState}, auth::types::AuthUser, models::calendar_event::{CalendarEvent, NewCalendarEvent, UpdatedCalendarEvent}
};

/// The query params for querying events.
#[derive(Deserialize)]
struct EventsQuery {
    start: DateTime<Utc>,
    end: DateTime<Utc>
}

/// Build the router for calendar event routes.
pub(super) fn router() -> Router<AppState> {
    Router::new()
        .route("/", post(create_events))
        .route("/", get(get_events))
        .route("/", put(update_event))
        .route("/{event_id}", delete(delete_event))
}

async fn create_events(
    State(app_state): State<AppState>,
    user: AuthUser,
    Json(events): Json<Vec<NewCalendarEvent>>
) -> ApiResult<()> {
    let calendar_service = app_state.services.calendar_events;
    calendar_service.create_events(user.id, events).await
}

async fn get_events(
    State(app_state): State<AppState>,
    Query(params): Query<EventsQuery>,
    user: AuthUser
) -> ApiResult<Json<Vec<CalendarEvent>>> {
    let calendar_service = app_state.services.calendar_events;
    let events = calendar_service.get_events(user.id, params.start, params.end).await?;
    Ok(Json(events))
}

async fn update_event(
    State(app_state): State<AppState>,
    user: AuthUser,
    Json(updated_event): Json<UpdatedCalendarEvent>
) -> ApiResult<()> {
    let calendar_service = app_state.services.calendar_events;
    calendar_service.update_event(user.id, updated_event).await
}

async fn delete_event(
    State(app_state): State<AppState>,
    Path(event_id): Path<Uuid>,
    user: AuthUser
) -> ApiResult<()> {
    let calendar_service = app_state.services.calendar_events;
    calendar_service.delete_event(user.id, event_id).await
}