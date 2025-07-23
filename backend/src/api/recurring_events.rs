use axum::{extract::{Path, Query, State}, routing::{delete, get, post, put}, Json, Router};
use chrono::{Date, DateTime, Utc};
use futures::future::join_all;
use rrule::RRuleResult;
use serde::Deserialize;
use uuid::Uuid;
use crate::{api::{auth::types::AuthUser, error::{ApiError, ApiResult}, AppState}, models::{calendar_event::CalendarEvent, recurring_event::{NewRecurringEvent, RecurringCalendarEvent, RecurringEvent}, recurring_event_exception::ExceptionType}};
use crate::models::rrule::ValidatedRRule;
use crate::models::recurring_event_exception::RecurringEventException;

/// The query params for querying events.
#[derive(Deserialize)]
struct EventsQuery {
    start: DateTime<Utc>,
    end: DateTime<Utc>
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
            (group_id, title, description, start_time, end_time)
            select * from unnest
            ($1::uuid[], $2::varchar[], $3::varchar[], $4::timestamptz[], $5::timestamptz[])
        "#,
        &group_ids[..],
        &titles[..],
        &descriptions[..] as &[Option<String>],
        &start_times[..],
        &end_times[..] as &[Option<DateTime<Utc>>]
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
    // fetch active recurring events within start/end dates
    let recurring_events: Vec<RecurringEvent> = sqlx::query_as!(
        RecurringEvent,
        r#"
            SELECT re.id, re.group_id, re.is_active, re.title, re.description, re.recurrence_start, re.recurrence_end, re.start_time, re.end_time, re.rrule as "rrule: _"
            FROM recurring_events re
            INNER JOIN recurring_event_groups reg ON reg.id = re.group_id
            WHERE reg.user_id = $1 AND re.recurrence_start > $2 AND re.recurrence_end < $3 AND re.is_active = true
        "#,
        user.id,
        params.start,
        params.end
    )
        .fetch_all(&app_state.db)
        .await?;

    // get actual event instances
    let events_and_instances: Vec<_> = recurring_events
        .into_iter()
        .map(|event| {
            let instances = event.rrule.all_within_period(params.start, params.end);
            (event, instances)
        })
        .collect();

    // get exceptions within start/end dates
    let mut event_exceptions: Vec<RecurringEventException> = {
        let event_ids: Vec<_> = events_and_instances.iter().map(|(e, _)| e.id).collect();
        sqlx::query_as!(
            RecurringEventException,
            r#"
                SELECT 
                    id, 
                    recurring_event_id, 
                    exception_date, 
                    exception_type as "exception_type: _",
                    modified_title,
                    modified_description,
                    modified_start_time,
                    modified_end_time
                FROM recurring_event_exceptions ree
                WHERE ree.recurring_event_id = ANY($1)
            "#,
            &event_ids
        )
            .fetch_all(&app_state.db)
            .await?      
    };

    // resolve instances and exceptions
    //
    // we remove "cancelled" + "modified" dates from each event, but retain "modified" exceptions for later use
    for (event, mut instances) in events_and_instances {
        event_exceptions = event_exceptions
            .into_iter()
            .filter(|exception| {
                if exception.recurring_event_id == event.id {
                    if let Some(pos) = instances.dates
                        .iter()
                        .position(|d| d.to_utc() == exception.exception_date) 
                    {   
                        instances.dates.swap_remove(pos);
                        match exception.exception_type {
                            ExceptionType::Cancelled => return false,
                            ExceptionType::Modified => return true
                        }
                    }
                }
                true
            }) 
            .collect();
    }

    // get group data for remaining instances

    unimplemented!();
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
                    description = $3,
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
            updated_event.rrule as ValidatedRRule,
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