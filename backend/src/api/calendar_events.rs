use axum::{extract::{Path, Query, State}, routing::{delete, get, post, put}, Json, Router};
use chrono::{DateTime, Utc};
use serde::Deserialize;
use uuid::Uuid;
use crate::{api::{auth::types::AuthUser, error::{ApiError, ApiResult}, AppState}, models::calendar_event::{CalendarEvent, NewCalendarEvent}};

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
    let mut user_ids = Vec::with_capacity(events.len());
    let mut titles = Vec::with_capacity(events.len());
    let mut descriptions = Vec::with_capacity(events.len());
    let mut start_times = Vec::with_capacity(events.len());
    let mut end_times = Vec::with_capacity(events.len());
    let mut locations = Vec::with_capacity(events.len());
    for event in events {
        user_ids.push(user.id);
        titles.push(event.title);
        descriptions.push(event.description);
        start_times.push(event.start_time);
        end_times.push(event.end_time);
        locations.push(event.location);
    }
    sqlx::query!(
        r#"
            insert into calendar_events
            (user_id, title, description, start_time, end_time, location)
            select * from unnest
            ($1::uuid[], $2::varchar[], $3::varchar[], $4::timestamptz[], $5::timestamptz[], $6::varchar[])
        "#,
        &user_ids[..],
        &titles[..],
        &descriptions[..] as &[Option<String>],
        &start_times[..],
        &end_times[..],
        &locations[..] as &[Option<String>]
    )
        .execute(&app_state.db)
        .await?;
    Ok(())
}

async fn get_events(
    State(app_state): State<AppState>,
    Query(params): Query<EventsQuery>,
    user: AuthUser
) -> ApiResult<Json<Vec<CalendarEvent>>> {
    let events = sqlx::query_as!(
        CalendarEvent,
        r#"
            select id, user_id, title, description, location, start_time, end_time
            from calendar_events 
            where user_id = $1 and start_time >= $2 and end_time <= $3
            order by start_time
        "#,
        user.id,
        params.start,
        params.end
    )
    .fetch_all(&app_state.db)
    .await?;
    Ok(Json(events))
}

async fn update_event(
    State(app_state): State<AppState>,
    user: AuthUser,
    Json(updated_event): Json<CalendarEvent>
) -> ApiResult<()> {
    let event_record = sqlx::query!(
        r#"select user_id from calendar_events where id = $1"#,
        updated_event.id
    )
        .fetch_one(&app_state.db)
        .await?;
    if event_record.user_id != user.id {
        return Err(ApiError::Forbidden);
    }
    else {
        sqlx::query!(
            r#"
                update calendar_events
                set 
                    title = $1,
                    description = $2,
                    location = $3,
                    start_time = $4,
                    end_time = $5
                where id = $6
            "#,
            updated_event.title,
            updated_event.description,
            updated_event.location,
            updated_event.start_time,
            updated_event.end_time,
            updated_event.id
        )
            .execute(&app_state.db)
            .await?;
        Ok(())
    }
}

async fn delete_event(
    State(app_state): State<AppState>,
    Path(event_id): Path<Uuid>,
    user: AuthUser
) -> ApiResult<()> {
    let event_record = sqlx::query!(
        r#"select user_id from calendar_events where id = $1"#,
        event_id
    )
        .fetch_one(&app_state.db)
        .await?;
    if event_record.user_id != user.id {
        return Err(ApiError::Forbidden);
    }
    else {
        sqlx::query!(
            r#"delete from calendar_events where id = $1"#,
            event_id
            )
            .execute(&app_state.db)
            .await?;
        Ok(())
    }
}