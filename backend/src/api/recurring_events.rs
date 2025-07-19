use axum::{extract::{Path, Query, State}, routing::{delete, get, post}, Json, Router};
use chrono::NaiveDateTime;
use serde::Deserialize;
use uuid::Uuid;
use crate::{api::{auth::types::AuthUser, error::{ApiError, ApiResult}, AppState}, models::{calendar_event::CalendarEvent, recurring_event::{NewRecurringEvent, RecurringEvent}}};

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
        .route("/", delete(delete_event))
}

async fn create_events(
    State(app_state): State<AppState>,
    user: AuthUser,
    Json(mut event): Json<Vec<NewRecurringEvent>>
) -> ApiResult<()> {

}

async fn get_events(
    State(app_state): State<AppState>,
    Query(params): Query<EventsQuery>,
    user: AuthUser
) -> ApiResult<Json<Vec<CalendarEvent>>> {

}

async fn update_event(
    State(app_state): State<AppState>,
    user: AuthUser,
    Json(updated_event): Json<RecurringEvent>
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