use std::collections::HashMap;
use axum::{
    extract::{Path, State}, 
    routing::{delete, get, post, put}, 
    Json, Router,
};
use serde::Serialize;
use uuid::Uuid;
use crate::{
    api::{auth::types::AuthUser, error::{ApiError, ApiResult}, AppState}, 
    models::{
        recurring_event::RecurringEvent, 
        recurring_event_group::{NewRecurringEventGroup, RecurringEventGroup}
    }
};

/// The response for a group (includes the number of events under the group).
#[derive(Serialize)]
struct RecurringEventGroupResponse {
    #[serde(flatten)]
    group: RecurringEventGroup,
    recurring_events: usize
}

/// Build the router for recurring event groups routes.
pub(super) fn router() -> Router<AppState> {
    Router::new()
        .route("/", get(fetch_all_groups))
        .route("/", post(add_group))
        .route("/{group_id}", delete(delete_group))
        .route("/{group_id}", get(fetch_events_for_group))
        .route("/{new_group_id}/move/{event_id}", put(move_event_between_groups))
}

async fn fetch_all_groups(
    State(app_state): State<AppState>,
    user: AuthUser,
) -> ApiResult<Json<Vec<RecurringEventGroupResponse>>> {
    let groups_with_counts = sqlx::query!(
        r#"
            SELECT 
                g.id,
                g.user_id,
                g.group_name,
                g.group_description,
                g.color,
                g.is_active,
                g.start_time,
                g.end_time,
                COALESCE(COUNT(e.id), 0) as event_count
            FROM recurring_event_groups g
            LEFT JOIN recurring_events e ON g.id = e.group_id
            WHERE g.user_id = $1
            GROUP BY g.id, g.user_id, g.group_name, g.group_description, g.color, g.is_active, g.start_time, g.end_time
            ORDER BY g.group_name
        "#,
        user.id
    )
        .fetch_all(&app_state.db)
        .await?;

    let response: Vec<RecurringEventGroupResponse> = groups_with_counts
        .into_iter()
        .map(|row| RecurringEventGroupResponse {
            group: RecurringEventGroup {
                id: row.id,
                user_id: row.user_id,
                group_name: row.group_name,
                group_description: row.group_description,
                color: row.color,
                is_active: row.is_active,
                start_time: row.start_time,
                end_time: row.end_time,
            },
            recurring_events: row.event_count.unwrap_or(0) as usize,
        })
        .collect();

    Ok(Json(response))
}

async fn add_group(
    State(app_state): State<AppState>,
    user: AuthUser,
    Json(new_group): Json<NewRecurringEventGroup>,
) -> ApiResult<()> {
    {
        let mut errors = HashMap::new();
        if new_group.group_name.trim().is_empty() {
            errors.insert("name", "is empty");
        }
        if new_group.color <= 0 {
            errors.insert("color", "is less than 0");
        }
        if let (Some(start), Some(end)) = (new_group.start_time, new_group.end_time) {
            if start >= end {
                errors.insert("start/end time",  "start time is later than end time");
            }
        }
        if !errors.is_empty() {
            return Err(ApiError::unprocessable_entity(errors));
        }
    }
    
    sqlx::query!(
        r#"
            INSERT INTO recurring_event_groups 
            (user_id, group_name, group_description, color, is_active, start_time, end_time)
            VALUES 
            ($1, $2, $3, $4, $5, $6, $7)
        "#,
        new_group.user_id,
        new_group.group_name,
        new_group.group_description,
        new_group.color,
        new_group.is_active,
        new_group.start_time,
        new_group.end_time
    )
        .execute(&app_state.db)
        .await?;

    Ok(())
}

async fn delete_group(
    State(app_state): State<AppState>,
    Path(group_id): Path<Uuid>,
    user: AuthUser,
) -> ApiResult<()> {
    let group = sqlx::query!(
        "SELECT id FROM recurring_event_groups WHERE id = $1 AND user_id = $2",
        group_id,
        user.id
    )
        .fetch_optional(&app_state.db)
        .await?;
    if group.is_none() {
        return Err(ApiError::Forbidden);
    }
    sqlx::query!(
        "DELETE FROM recurring_events WHERE group_id = $1",
        group_id
    )
        .execute(&app_state.db)
        .await?;
    sqlx::query!(
        "DELETE FROM recurring_event_groups WHERE id = $1 AND user_id = $2",
        group_id,
        user.id
    )
        .execute(&app_state.db)
        .await?;

    Ok(())
}

async fn fetch_events_for_group(
    State(app_state): State<AppState>,
    Path(group_id): Path<Uuid>,
    user: AuthUser,
) -> ApiResult<Json<Vec<RecurringEvent>>> {
    let group_exists = sqlx::query!(
        "SELECT id FROM recurring_event_groups WHERE id = $1 AND user_id = $2",
        group_id,
        user.id
    )
        .fetch_optional(&app_state.db)
        .await?;
    if group_exists.is_none() {
        return Err(ApiError::Forbidden);
    }

    let events = sqlx::query_as!(
        RecurringEvent,
        r#"
            SELECT id, group_id, title, event_description as "description", start_time, end_time, rrule
            FROM recurring_events
            WHERE group_id = $1
            ORDER BY start_time, title
        "#,
        group_id
    )
        .fetch_all(&app_state.db)
        .await?;

    Ok(Json(events))
}

async fn move_event_between_groups(
    State(app_state): State<AppState>,
    Path((new_group_id, event_id)): Path<(Uuid, Uuid)>,
    user: AuthUser,
) -> ApiResult<()> {
    let target_group = sqlx::query!(
        "SELECT id FROM recurring_event_groups WHERE id = $1 AND user_id = $2",
        new_group_id,
        user.id
    )
        .fetch_optional(&app_state.db)
        .await?;
    if target_group.is_none() {
        return Err(ApiError::Forbidden);
    }

    let event_info = sqlx::query!(
        r#"
            SELECT e.id, e.group_id, g.user_id
            FROM recurring_events e
            JOIN recurring_event_groups g ON e.group_id = g.id
            WHERE e.id = $1 AND g.user_id = $2
        "#,
        event_id,
        user.id
        )
        .fetch_optional(&app_state.db)
        .await?;
    match event_info {
        None => return Err(ApiError::Forbidden),
        Some(event) => {
            if event.group_id == new_group_id {
                return Err(ApiError::Forbidden);
            }
        }
    }

    sqlx::query!(
        "UPDATE recurring_events SET group_id = $1 WHERE id = $2",
        new_group_id,
        event_id
    )
        .execute(&app_state.db)
        .await?;

    Ok(())
}