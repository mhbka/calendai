use axum::{
    extract::{Path, Query, State}, 
    routing::{delete, get, post, put}, 
    Json, Router
};
use uuid::Uuid;
use crate::{
    auth::types::AuthUser,
    models::{
        recurring_event::{NewRecurringEvent, RecurringCalendarEvent, UpdatedRecurringEvent},
        recurring_event_exception::{NewRecurringEventException, RecurringEventException}
    }, services::recurring_events_service::EventsQuery
};
use crate::{
    api::{error::ApiResult, AppState}
};

pub(super) fn router() -> Router<AppState> {
    Router::new()
        .route("/", post(create_events))
        .route("/", get(get_events))
        .route("/", put(update_event))
        .route("/{event_id}", delete(delete_event))
        .route("/exception", post(create_event_exception))
        .route("/exception", put(update_event_exception))
}

async fn create_events(
    State(app_state): State<AppState>,
    user: AuthUser,
    Json(events): Json<Vec<NewRecurringEvent>>
) -> ApiResult<()> {
    let service = app_state.services.recurring_events;
    service.create_events(user.id, events).await?;
    Ok(())
}

async fn get_events(
    State(app_state): State<AppState>,
    Query(params): Query<EventsQuery>,
    user: AuthUser
) -> ApiResult<Json<Vec<RecurringCalendarEvent>>> {
    let service = app_state.services.recurring_events;
    let events = service.get_events(user.id, params).await?;
    Ok(Json(events))
}

async fn update_event(
    State(app_state): State<AppState>,
    user: AuthUser,
    Json(updated_event): Json<UpdatedRecurringEvent>
) -> ApiResult<()> {
    let service = app_state.services.recurring_events;
    service.update_event(user.id, updated_event).await?;
    Ok(())
}

async fn delete_event(
    State(app_state): State<AppState>,
    Path(event_id): Path<Uuid>,
    user: AuthUser
) -> ApiResult<()> {
    let service = app_state.services.recurring_events;
    service.delete_event(user.id, event_id).await?;
    Ok(())
}

async fn create_event_exception(
    State(app_state): State<AppState>,
    user: AuthUser,
    Json(exception): Json<NewRecurringEventException>
) -> ApiResult<()> {
    let service = app_state.services.recurring_events;
    service.create_event_exception(user.id, exception).await?;
    Ok(())
}

async fn update_event_exception(
    State(app_state): State<AppState>,
    user: AuthUser,
    Json(exception): Json<RecurringEventException>
) -> ApiResult<()> {
    let service = app_state.services.recurring_events;
    service.update_event_exception(user.id, exception).await?;
    Ok(())
}