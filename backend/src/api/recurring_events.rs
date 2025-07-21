use axum::{extract::{Path, Query, State}, routing::{delete, get, post, put}, Json, Router};
use chrono::NaiveDateTime;
use serde::Deserialize;
use uuid::Uuid;
use crate::{api::{auth::types::AuthUser, error::{ApiError, ApiResult}, AppState}, models::{calendar_event::CalendarEvent, recurring_event::{NewRecurringEvent, RecurringCalendarEvent, RecurringEvent}}};

/// The query params for querying events.
#[derive(Deserialize)]
struct EventsQuery {
    start: NaiveDateTime,
    end: NaiveDateTime
}

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
    Json(events): Json<Vec<NewRecurringEvent>>
) -> ApiResult<()> {
    let mut group_ids = Vec::with_capacity(events.len());
    let mut titles = Vec::with_capacity(events.len());
    let mut descriptions = Vec::with_capacity(events.len());
    let mut start_times = Vec::with_capacity(events.len());
    let mut end_times = Vec::with_capacity(events.len());
    for event in events {
        group_ids.push(event.group_id);
        titles.push(event.title);
        descriptions.push(event.description);
        start_times.push(event.start_time);
        end_times.push(event.end_time);
    }

    let authorized_groups = sqlx::query!(
    r#"
        select id from recurring_event_groups 
        where id = any($1) and user_id = $2
    "#,
    &group_ids[..],
    user.id
    )
        .fetch_all(&app_state.db)
        .await?;
    if (authorized_groups.len()) != group_ids.len() {
        return Err(ApiError::Forbidden);
    }
    
    sqlx::query!(
        r#"
            insert into recurring_events
            (group_id, title, event_description, start_time, end_time)
            select * from unnest
            ($1::uuid[], $2::varchar[], $3::varchar[], $4::timestamp[], $5::timestamp[])
        "#,
        &group_ids[..],
        &titles[..],
        &descriptions[..] as &[Option<String>],
        &start_times[..],
        &end_times[..] as &[Option<NaiveDateTime>]
    )
        .execute(&app_state.db)
        .await?;
    Ok(())
}

async fn get_events(
    State(app_state): State<AppState>,
    Query(params): Query<EventsQuery>,
    user: AuthUser
) -> ApiResult<Json<Vec<RecurringCalendarEvent>>> {
    // TODO: 
    // - get active events within query dates
    // - get exceptions for those events within query dates
    // - convert to RecurringCalendarEvents
    let active_events = sqlx::query!(
        r#"
            SELECT * FROM recurring_events
            WHERE start_time > $1 AND end_time < $2
            
        "#
    )

    unimplemented!()
}

async fn update_event(
    State(app_state): State<AppState>,
    user: AuthUser,
    Json(updated_event): Json<RecurringEvent>
) -> ApiResult<()> {
    let event_record = sqlx::query!(
        r#"
            SELECT recurring_event_groups.user_id
            FROM recurring_events 
            INNER JOIN recurring_event_groups ON recurring_events.group_id = recurring_event_groups.id
            WHERE recurring_events.id = $1
        "#,
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
                update recurring_events
                set 
                    title = $1,
                    group_id = $2,
                    event_description = $3,
                    start_time = $4,
                    end_time = $5,
                    rrule = $6
                where id = $7
            "#,
            updated_event.title,
            updated_event.group_id,
            updated_event.description,
            updated_event.start_time,
            updated_event.end_time,
            updated_event.rrule,
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
        r#"
            select recurring_event_groups.user_id
            from recurring_events 
            inner join recurring_event_groups on recurring_events.group_id = recurring_event_groups.id
            where recurring_events.id = $1
        "#,
        event_id
    )
        .fetch_one(&app_state.db)
        .await?;
    if event_record.user_id != user.id {
        return Err(ApiError::Forbidden);
    }
    else {
        sqlx::query!(
            r#"delete from recurring_events where id = $1"#,
            event_id
            )
            .execute(&app_state.db)
            .await?;
        Ok(())
    }
}