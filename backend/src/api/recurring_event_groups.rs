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
        recurring_event_group::{NewRecurringEventGroup, RecurringEventGroup, UpdatedRecurringEventGroup}
    }
};

/// The response for a group (includes the number of events under the group).
#[derive(Serialize)]
struct RecurringEventGroupResponse {
    #[serde(flatten)]
    group: RecurringEventGroup,
    #[serde(rename(serialize = "recurringEvents"))]
    recurring_events: usize
}

/// Build the router for recurring event groups routes.
pub(super) fn router() -> Router<AppState> {
    Router::new()
        .route("/", get(fetch_all_groups))
        .route("/", post(add_group))
        .route("/", put(update_group))
        .route("/{group_id}", delete(delete_group))
        .route("/{group_id}", get(fetch_group))
        .route("/{group_id}/events", get(fetch_events_for_group))
        .route("/ungrouped/events", get(fetch_ungrouped_events))
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
                g.name,
                g.description,
                g.color,
                g.group_is_active,
                g.group_recurrence_start,
                g.group_recurrence_end,
                COALESCE(COUNT(e.id), 0) as event_count
            FROM recurring_event_groups g
            LEFT JOIN recurring_events e ON g.id = e.group_id
            WHERE g.user_id = $1
            GROUP BY g.id, g.user_id, g.name, g.description, g.color, g.group_is_active, g.group_recurrence_start, g.group_recurrence_end
            ORDER BY g.name
        "#,
        user.id
    )
        .fetch_all(&app_state.db)
        .await?;
    let mut response: Vec<RecurringEventGroupResponse> = groups_with_counts
        .into_iter()
        .map(|row| RecurringEventGroupResponse {
            group: RecurringEventGroup {
                id: row.id,
                user_id: row.user_id,
                name: row.name,
                description: row.description,
                color: row.color,
                group_is_active: row.group_is_active,
                group_recurrence_start: row.group_recurrence_start,
                group_recurrence_end: row.group_recurrence_end,
            },
            recurring_events: row.event_count.unwrap_or(0) as usize,
        })
        .collect();

    let groupless_event_count = sqlx::query_scalar!(
        r#"
            SELECT COUNT(*)
            FROM recurring_events re
            WHERE group_id IS NULL AND user_id = $1
        "#,
        user.id
    )
        .fetch_one(&app_state.db)
        .await?
        .unwrap_or(0);
    let ungrouped_group = RecurringEventGroup {
        id: Uuid::nil(),
        user_id: user.id,
        name: "Ungrouped".to_string(),
        description: Some("Events that don't belong to any group".to_string()),
        color: u32::MAX as i64,
        group_is_active: None,
        group_recurrence_start: None,
        group_recurrence_end: None
    };
    response.push(RecurringEventGroupResponse { group: ungrouped_group, recurring_events: groupless_event_count as usize });

    Ok(Json(response))
}

async fn fetch_group(
    State(app_state): State<AppState>,
    user: AuthUser,
    Path(group_id): Path<Uuid>,
) -> ApiResult<Json<RecurringEventGroupResponse>> {
    let row = sqlx::query!(
        r#"
            SELECT 
                g.id,
                g.user_id,
                g.name,
                g.description,
                g.color,
                g.group_is_active,
                g.group_recurrence_start,
                g.group_recurrence_end,
                COALESCE(COUNT(e.id), 0) as event_count
            FROM recurring_event_groups g
            LEFT JOIN recurring_events e ON g.id = e.group_id
            WHERE g.user_id = $1 AND g.id = $2
            GROUP BY g.id, g.user_id, g.name, g.description, g.color, g.group_is_active, g.group_recurrence_start, g.group_recurrence_end
        "#,
        user.id,
        group_id
    )
        .fetch_one(&app_state.db)
        .await?;
    let response = RecurringEventGroupResponse {
            group: RecurringEventGroup {
                id: row.id,
                user_id: row.user_id,
                name: row.name,
                description: row.description,
                color: row.color,
                group_is_active: row.group_is_active,
                group_recurrence_start: row.group_recurrence_start,
                group_recurrence_end: row.group_recurrence_end,
            },
            recurring_events: row.event_count.unwrap_or(0) as usize,
        };
    Ok(Json(response))
}

async fn add_group(
    State(app_state): State<AppState>,
    user: AuthUser,
    Json(new_group): Json<NewRecurringEventGroup>,
) -> ApiResult<()> {
    {
        let mut errors = HashMap::new();
        if new_group.name.trim().is_empty() {
            errors.insert("name", "is empty");
        }
        if new_group.color <= 0 {
            errors.insert("color", "is less than 0");
        }
        if let (Some(start), Some(end)) = (new_group.group_recurrence_start, new_group.group_recurrence_start) {
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
            (user_id, name, description, color, group_is_active, group_recurrence_start, group_recurrence_end)
            VALUES 
            ($1, $2, $3, $4, $5, $6, $7)
        "#,
        user.id,
        new_group.name,
        new_group.description,
        new_group.color as i64,
        new_group.group_is_active,
        new_group.group_recurrence_start,
        new_group.group_recurrence_end
    )
        .execute(&app_state.db)
        .await?;

    Ok(())
}

async fn update_group(
    State(app_state): State<AppState>,
    user: AuthUser,
    Json(updated_group): Json<UpdatedRecurringEventGroup>,
) -> ApiResult<()> {
    let group = sqlx::query!(
        "SELECT id FROM recurring_event_groups WHERE id = $1 AND user_id = $2",
        updated_group.id,
        user.id
    )
        .fetch_optional(&app_state.db)
        .await?;
    if group.is_none() {
        return Err(ApiError::Forbidden);
    }
    else {
        sqlx::query!(
            r#"
                UPDATE recurring_event_groups
                SET
                    name = $1,
                    description = $2,
                    color = $3,
                    group_is_active = $4,
                    group_recurrence_start = $5,
                    group_recurrence_end = $6
                WHERE id = $7
            "#,
            updated_group.name,
            updated_group.description,
            updated_group.color,
            updated_group.group_is_active,
            updated_group.group_recurrence_start,
            updated_group.group_recurrence_end,
            updated_group.id
        )
            .execute(&app_state.db)
            .await?;
        Ok(())
    }
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
    else {
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
            SELECT 
                id, 
                group_id, 
                user_id,
                is_active, 
                title, 
                description, 
                location, 
                event_duration_seconds as "event_duration_seconds: _", 
                recurrence_start, 
                recurrence_end, 
                rrule as "rrule: _"
            FROM recurring_events
            WHERE group_id = $1
        "#,
        group_id
    )
        .fetch_all(&app_state.db)
        .await?;

    Ok(Json(events))
}

async fn fetch_ungrouped_events(
    State(app_state): State<AppState>,
    user: AuthUser,
) -> ApiResult<Json<Vec<RecurringEvent>>> {
    let events = sqlx::query_as!(
        RecurringEvent,
        r#"
            SELECT 
                id, 
                group_id, 
                user_id,
                is_active, 
                title, 
                description, 
                location, 
                event_duration_seconds as "event_duration_seconds: _", 
                recurrence_start, 
                recurrence_end, 
                rrule as "rrule: _"
            FROM recurring_events
            WHERE user_id = $1 AND group_id IS NULL
        "#,
        user.id
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
            if event.group_id == Some(new_group_id) {
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