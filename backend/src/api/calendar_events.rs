use axum::{debug_handler, extract::{Path, Query, State}, routing::{delete, get, post, put}, Json, Router};
use chrono::{DateTime, Utc};
use serde::Deserialize;
use uuid::Uuid;
use crate::{api::{auth::types::AuthUser, error::ApiResult, AppState}, models::calendar_event::{CalendarEvent, NewCalendarEvent}};

/// The query params for querying events.
#[derive(Deserialize)]
struct EventsQuery {
    start: DateTime<Utc>,
    end: DateTime<Utc> 
}

/// Build the router for calendar event routes.
pub(super) fn router() -> Router<AppState> {
    Router::new()
        .route("/", post(create_event))
        .route("/", get(get_events))
        .route("/{event_id}", put(update_event))
        .route("/{event_id}", delete(delete_event))
}

async fn create_event(
    State(mut app_state): State<AppState>,
    user: AuthUser,
    Json(mut event): Json<NewCalendarEvent>
) -> ApiResult<()> {
    event.user_id = user.id;

    sqlx::query!(
        r#"
            insert into calendar_events 
            (user_id, title, event_description, start_time, end_time)
            values
            ($1, $2, $3, $4, $5)
        "#,
        event.user_id,
        event.title,
        event.description,
        event.start_time.naive_utc(),
        event.end_time.naive_utc()
    )
        .execute(&app_state.db)
        .await?;

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