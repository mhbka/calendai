use axum::{
    extract::{Path, State}, 
    routing::{delete, get, post, put}, 
    Json, Router,
};
use uuid::Uuid;
use crate::{
    api::{error::ApiResult, AppState}, 
    auth::types::AuthUser,
    models::{
        recurring_event::RecurringEvent,
        recurring_event_group::{NewRecurringEventGroup, UpdatedRecurringEventGroup}
    }, services::recurring_event_groups_service::{GroupWithEvents, RecurringEventGroupResponse}
};

/// Build the router for recurring event groups routes.
pub(super) fn router() -> Router<AppState> {
    Router::new()
        .route("/", get(fetch_all_groups))
        .route("/", post(add_group))
        .route("/", put(update_group))
        .route("/with_events", post(add_with_events))
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
    let service = app_state.services.recurring_event_groups;
    let groups = service.fetch_all_groups(user.id).await?;
    Ok(Json(groups))
}

async fn fetch_group(
    State(app_state): State<AppState>,
    user: AuthUser,
    Path(group_id): Path<Uuid>,
) -> ApiResult<Json<RecurringEventGroupResponse>> {
    let service = app_state.services.recurring_event_groups;
    let group = service.fetch_group(user.id, group_id).await?;
    Ok(Json(group))
}

async fn add_group(
    State(app_state): State<AppState>,
    user: AuthUser,
    Json(new_group): Json<NewRecurringEventGroup>,
) -> ApiResult<()> {
    let service = app_state.services.recurring_event_groups;
    service.add_group(user.id, new_group).await?;
    Ok(())
}

async fn update_group(
    State(app_state): State<AppState>,
    user: AuthUser,
    Json(updated_group): Json<UpdatedRecurringEventGroup>,
) -> ApiResult<()> {
    let service = app_state.services.recurring_event_groups;
    service.update_group(user.id, updated_group).await?;
    Ok(())
}

async fn delete_group(
    State(app_state): State<AppState>,
    Path(group_id): Path<Uuid>,
    user: AuthUser,
) -> ApiResult<()> {
    let service = app_state.services.recurring_event_groups;
    service.delete_group(user.id, group_id).await?;
    Ok(())
}

async fn add_with_events(
    State(app_state): State<AppState>,
    user: AuthUser,
    Json(events): Json<GroupWithEvents>
) -> ApiResult<()> {
    let service = app_state.services.recurring_event_groups;
    service.add_with_events(user.id, events).await?;
    Ok(())
}

async fn fetch_events_for_group(
    State(app_state): State<AppState>,
    Path(group_id): Path<Uuid>,
    user: AuthUser,
) -> ApiResult<Json<Vec<RecurringEvent>>> {
    let service = app_state.services.recurring_event_groups;
    let events = service.fetch_events_for_group(user.id, group_id).await?;
    Ok(Json(events))
}

async fn fetch_ungrouped_events(
    State(app_state): State<AppState>,
    user: AuthUser,
) -> ApiResult<Json<Vec<RecurringEvent>>> {
    let service = app_state.services.recurring_event_groups;
    let events = service.fetch_ungrouped_events(user.id).await?;
    Ok(Json(events))
}

async fn move_event_between_groups(
    State(app_state): State<AppState>,
    Path((new_group_id, event_id)): Path<(Uuid, Uuid)>,
    user: AuthUser,
) -> ApiResult<()> {
    let service = app_state.services.recurring_event_groups;
    service.move_event_between_groups(user.id, new_group_id, event_id).await?;
    Ok(())
}